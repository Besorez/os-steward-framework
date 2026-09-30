#!/bin/bash
# SYNOPSIS
#   Turn on macOS File Sharing (smbd) and give one account an SMB-NT password hash so
#   Windows can log in to \\mac\<user> with the normal Mac password.
# USAGE
#   sudo bash enable-smb-sharing.sh [user]        (user defaults to the account that ran sudo)
#   From Windows: Invoke-MacSudoScript.ps1 -ScriptPath .\enable-smb-sharing.sh
# WHY
#   Without an SMB-NT hash (pwpolicy -gethashtypes lists only SALTED-SHA512-PBKDF2 and SRP)
#   Windows is refused with "user name or password is incorrect" even with the right password.
#   The hash is generated only when the password is set, so the script re-sets the password to
#   the SAME value with "dscl . -passwd" run AS THE USER (old + new): unlike an admin reset this
#   keeps the login keychain and the secure token intact. The password is read silently (read -s),
#   never taken from argv; it is briefly on dscl's argv on the Mac itself.
# ROLLBACK
#   pwpolicy -u <user> -sethashtypes SMB-NT off
#   launchctl disable system/com.apple.smbd ; launchctl bootout system/com.apple.smbd
#   (or System Settings > General > Sharing > File Sharing off)
set -euo pipefail
U="${1:-${SUDO_USER:-}}"
[ "$(id -u)" -eq 0 ] || { echo "run with sudo" >&2; exit 1; }
[ -n "$U" ] && id "$U" >/dev/null 2>&1 || { echo "unknown user '$U'" >&2; exit 1; }

echo "== File Sharing (smbd)"
launchctl enable system/com.apple.smbd
launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.smbd.plist 2>/dev/null || true

echo "== SMB-NT hash for $U"
echo "before: $(pwpolicy -u "$U" -gethashtypes 2>/dev/null | tr '\n' ' ')"
pwpolicy -u "$U" -sethashtypes SMB-NT on
read -r -s -p "Current Mac password of $U (re-set to the same value): " PW; echo
sudo -u "$U" dscl . -passwd "/Users/$U" "$PW" "$PW"
PW=""
echo "after:  $(pwpolicy -u "$U" -gethashtypes 2>/dev/null | tr '\n' ' ')"
echo "== DONE: from Windows map \\\\<mac>\\$U (Connect-MacDrive.ps1)"

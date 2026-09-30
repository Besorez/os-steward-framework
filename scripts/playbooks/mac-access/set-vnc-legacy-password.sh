#!/bin/bash
# SYNOPSIS
#   Let password-only VNC viewers (security type 2, VncAuth) into macOS Screen Sharing by
#   setting a legacy VNC password. Without it Apple offers only its own types (30 = ARD
#   user + password, 33/35/36), which most Windows viewers either pick or cannot do.
# USAGE
#   sudo bash set-vnc-legacy-password.sh [password-file]
#   With a file, its first line is the password; otherwise it is read silently (read -s).
#   Never pass the password itself as an argument. VncAuth uses at most 8 characters.
#   From Windows: Invoke-MacSudoScript.ps1 -ScriptPath .\set-vnc-legacy-password.sh
# CHECK
#   defaults read /Library/Preferences/com.apple.RemoteManagement VNCLegacyConnectionsEnabled  -> 1
#   From Windows: Test-VncSecurityTypes.ps1 now lists 2; Test-VncPassword.ps1 prints the framebuffer.
# ROLLBACK
#   sudo $KS -configure -clientopts -setvnclegacy -vnclegacy no
#   (KS = the kickstart path below); then: launchctl kickstart -k system/com.apple.screensharing
set -euo pipefail
KS=/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart
[ "$(id -u)" -eq 0 ] || { echo "run with sudo" >&2; exit 1; }
[ -x "$KS" ] || { echo "kickstart not found at $KS" >&2; exit 1; }

if [ -n "${1:-}" ]; then
  IFS= read -r VNCPW < "$1"
else
  read -r -s -p "VNC password (max 8 characters): " VNCPW; echo
fi
[ -n "$VNCPW" ] || { echo "empty password" >&2; exit 1; }
[ "${#VNCPW}" -le 8 ] || echo "warning: VncAuth uses only the first 8 characters" >&2

"$KS" -configure -clientopts -setvnclegacy -vnclegacy yes -setvncpw -vncpw "$VNCPW" >/dev/null
VNCPW=""
launchctl kickstart -k system/com.apple.screensharing 2>/dev/null || true
echo "VNCLegacyConnectionsEnabled = $(defaults read /Library/Preferences/com.apple.RemoteManagement VNCLegacyConnectionsEnabled 2>/dev/null || echo '?')"

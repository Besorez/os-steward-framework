# mac-access/

Shell, file and screen access to a Mac on the LAN from a Windows operator.
Case: [Remote-Mac-Access-From-Windows](../../../docs/playbooks/Remote-Mac-Access-From-Windows.md).
PowerShell scripts run on the **operator**; `.sh` scripts run **on the Mac
with sudo** (copied and started by `Invoke-MacSudoScript.ps1`). Each is
read-only or a reversible step with its rollback in the header comment.
Secrets are read from a prompt or a per-user file, never from a command
line; files go to `%LOCALAPPDATA%\OSSteward-playbooks\mac-access`.

Discovery first: `..\network\Test-LanHosts.ps1 -Subnet 192.0.2 -Ports 22,445,5900 -ProbeAll`.

| # | Script | Side | Kind | What it does | Playbook |
|---|---|---|---|---|---|
| 1 | [Install-MacSshKey.ps1](Install-MacSshKey.ps1) | operator | reversible | Pushes `id_ed25519.pub` with one password prompt, adds `Host <alias>` to `~/.ssh/config`, verifies with `BatchMode` | §2.1 |
| 2 | [Invoke-MacSudoScript.ps1](Invoke-MacSudoScript.ps1) | operator | runner | Copies a `.sh` to `/tmp` on the Mac and runs `ssh -t <alias> sudo bash ...` in a visible window titled *MAC PASSWORD* that closes on Enter | §2.2 |
| 3 | [enable-smb-sharing.sh](enable-smb-sharing.sh) | Mac, sudo | reversible | Starts `smbd`; `pwpolicy -sethashtypes SMB-NT on`; re-sets the same password as the user (`dscl . -passwd`) so the NT hash exists, keychain and secure token intact | §2.3 |
| 4 | [Connect-MacDrive.ps1](Connect-MacDrive.ps1) | operator | reversible | `Get-Credential` → `cmdkey` → `net use M: \\host\<user> /persistent:yes` | §2.3 |
| 5 | [set-vnc-legacy-password.sh](set-vnc-legacy-password.sh) | Mac, sudo | reversible | ARD `kickstart -setvnclegacy -vnclegacy yes -setvncpw` so the server also offers VncAuth (type 2) | §3 |
| 6 | [Test-VncSecurityTypes.ps1](Test-VncSecurityTypes.ps1) | operator | read-only | RFB handshake: server version and offered security types in server order | §3 |
| 7 | [New-VncPasswordFile.ps1](New-VncPasswordFile.ps1) | operator | file write | Generates the 8-character password file if missing; writes the obfuscated `vncpasswd` file for `TigerVNC -PasswordFile=` | §3 |
| 8 | [Test-VncPassword.ps1](Test-VncPassword.ps1) | operator | read-only | Completes VncAuth and reads ServerInit: framebuffer size + desktop name, independent of any viewer | §3 |
| 9 | [Start-MacScreen.ps1](Start-MacScreen.ps1) | operator | processes | Hidden `websockify` serving a (patched) noVNC on `127.0.0.1:6080`, Chrome `--app` window with its own profile, `resize=scale` | §4 |
| 10 | [set-no-sleep-on-ac.sh](set-no-sleep-on-ac.sh) | Mac, sudo | reversible | `pmset -c sleep 0 womp 1 tcpkeepalive 1`, prints before/after | §5 |

Operator prerequisites for §4: Python with `py -m pip install websockify`,
an unpacked noVNC release (not vendored here) patched as described in the
playbook, Chrome.

# Playbook: Remote Mac Access From Windows

> **Status: Current** (field-verified 2026-09). MacBook with macOS 26/27 on
> Wi-Fi, Windows 11 operator machine, same LAN, home router with DHCP.
> Examples use `192.0.2.0/24`; the Mac is `192.0.2.40`, the user `TestUser`.
> Scripts: [`scripts/playbooks/mac-access/`](../../scripts/playbooks/mac-access/README.md).

## Goal

From the Windows machine: a shell on the Mac with a key, the Mac home folder
as a Windows drive letter, and the Mac screen in a window that fits the
operator's monitor — without sitting at the Mac.

## 1. Find the Mac

Sweep with the Mac ports instead of RDP:
`Test-LanHosts.ps1 -Subnet 192.0.2 -Ports 22,445,5900 -ProbeAll`.

| Port | Open means | Evidence of an Apple host |
|---|---|---|
| 22 | *Remote Login* is on | banner `SSH-2.0-OpenSSH_10.x` |
| 5900 | *Screen Sharing* is on | RFB banner **`RFB 003.889`** (Apple's own version string) |
| 445 | *File Sharing* is on | closed in this case — off by default |

The Mac's Wi-Fi MAC is locally administered (private Wi-Fi address), so
vendor lookup says nothing; the banners do. The mDNS name resolves with
`Resolve-DnsName <name>.local -LlmnrNetbiosOnly`. Reserve the address on
the router: the private MAC is stable per network unless rotation is set
to *rotating*, so a reservation holds.

## 2. Shell and files

1. **SSH key** — `Install-MacSshKey.ps1 -HostName 192.0.2.40 -User TestUser`:
   one password prompt, a `Host mac` alias, verified with `BatchMode=yes`.
2. **sudo needs a terminal.** `ssh mac sudo ...` fails with *"a password
   is required"*. Run Mac-side scripts through `ssh -t mac "sudo bash
   script"` in a visible window (`Invoke-MacSudoScript.ps1`). Give password
   windows a distinctive title and close them when done: in the field a
   password was typed into an old, finished PowerShell window, which ran it
   as a command and stored it in PSReadLine history
   (`%APPDATA%\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt`
   — the owner removes that line).
3. **SMB** — `enable-smb-sharing.sh`, then `Connect-MacDrive.ps1`.
   Turning File Sharing on is not enough: Windows is refused with *"user
   name or password is incorrect"* with the correct password.

   | Evidence | Meaning |
   |---|---|
   | `pwpolicy -u TestUser -gethashtypes` → `SALTED-SHA512-PBKDF2 SRP` only | no NT hash — SMB/NTLM cannot validate |
   | after `-sethashtypes SMB-NT on` + password re-set → `SMB-NT` listed | Windows login works |

   The hash is only produced when a password is *set*. Re-set it to the same
   value **as the user**: `dscl . -passwd /Users/TestUser <old> <new>`. An
   admin reset (without the old password) would detach the login keychain
   and can drop the secure token. Result: `\\192.0.2.40\TestUser` = the home
   folder, mapped persistently as `M:`.

## 3. Screen: which authentication the viewer picks

`Test-VncSecurityTypes.ps1` against Apple Screen Sharing:

| Server offers (in order) | Meaning |
|---|---|
| `30,33,36,35` | 30 = ARD Diffie-Hellman (Mac user + password); 33/35/36 Apple-specific |
| `30,33,36,2,35` | plus **2 = VncAuth** (password only) — only after `set-vnc-legacy-password.sh` (`VNCLegacyConnectionsEnabled = 1` in `com.apple.RemoteManagement`) |

Viewers take the **first type they support in server order**, so TigerVNC
and noVNC still ask for user name + password (type 30) after the legacy
password exists. Force type 2:

- **TigerVNC**: `vncviewer -SecurityTypes=VncAuth -PasswordFile=<file> 192.0.2.40`
  (`New-VncPasswordFile.ps1` writes the obfuscated file: password padded
  to 8 bytes, DES-ECB with the fixed key `23,82,107,6,35,78,88,7`, bits of
  each key byte reversed).
- **noVNC** has no option. Local patch in `core/rfb.js`,
  `_negotiateSecurity()`: after reading the server's type list and before
  the loop that picks the first supported type, set
  `this._rfbAuthScheme = securityTypeVNCAuth` when
  `types.includes(securityTypeVNCAuth)`, and let the loop run only while
  the scheme is still `-1`. noVNC is not vendored here;
  `Start-MacScreen.ps1` takes its path and warns if the patch is missing.

Before blaming a viewer, prove the password: `Test-VncPassword.ps1` completes
VncAuth and prints the framebuffer (`3456x2234` on a Retina MacBook) and the
desktop name.

## 4. Screen: fitting a Retina framebuffer on the operator monitor

`3456x2234` does not fit `2560x1440`. What was tried:

| Viewer | Outcome |
|---|---|
| TigerVNC 1.16 | connects (type 2), **no client-side scaling** |
| Resize from the client | Mac ignores `SetDesktopSize` / remote resize |
| UltraVNC 1.8 | "Failed to connect to server" against `RFB 003.889` |
| RealVNC Viewer | winget installer URLs 404; vendor site answers 403 to scripts |
| TightVNC | download failed `0x80072efd` |
| **noVNC + websockify, `resize=scale`** | **works** — scaled to the window |

`Start-MacScreen.ps1` starts `pyw -m websockify --web <noVNC> 127.0.0.1:6080
192.0.2.40:5900` hidden when the port is not listening and opens Chrome
`--app` on `vnc.html?autoconnect=1&resize=scale&reconnect=1&path=websockify`.
Chrome kept serving the **cached unpatched `rfb.js`** from the normal
profile, so the window uses its own `--user-data-dir`;
`--disable-features=Translate` stops the translate bar on the Mac UI.

**Keyboard:** noVNC and TigerVNC send keysyms from the *Windows* layout.
With a Cyrillic layout active, a Latin password typed at the Mac lock screen
arrives as Cyrillic and fails — switch the operator layout to EN first.

**Cleanup rule:** uninstall the viewers that were tried and failed
(`winget uninstall <id>`, owner-run) so only the working path remains.

## 5. Keep it reachable

`set-no-sleep-on-ac.sh`: `pmset -c sleep 0 womp 1 tcpkeepalive 1` keeps the
Mac awake on the charger (rollback `pmset -c sleep 1`). A closed lid still
sleeps (clamshell mode needs an external display) — leave it open. DHCP
reservation as in §1.

## 6. Verification

- `ssh -o BatchMode=yes mac 'hostname; sw_vers -productVersion'` answers
  without a prompt.
- `Get-SmbMapping` shows `M:` → `\\192.0.2.40\TestUser` as `OK`.
- `Test-VncSecurityTypes.ps1` lists `2`; `Test-VncPassword.ps1` prints
  `VncAuth OK ... 3456x2234`.
- `Start-MacScreen.ps1` shows the Mac desktop scaled to the window; mouse
  and keyboard (EN layout) work at the lock screen.

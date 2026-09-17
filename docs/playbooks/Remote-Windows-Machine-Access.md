# Playbook: Remote Windows Machine Access

> **Status: Current** (field-verified 2026-09). Windows 10/11 target,
> Windows 11 operator machine, home router with DHCP. Examples use
> `192.0.2.0/24`; the target is `192.0.2.51`, the operator `192.0.2.167`.

## Goal

Administer a second Windows machine on the same LAN from the operator's
machine without sitting at it: shell with admin rights, file access to
every drive, full desktop, and the ability to power it on and off.

## 1. Find the machine (and why it may be invisible)

Sweep the subnet for ICMP and the three service ports
(`scripts/playbooks/Test-LanHosts.ps1`). Expect only the router and the
operator on the first pass; the target is usually hidden by one of these,
in order of how often they were the real cause:

| Symptom on the operator | Cause | Evidence | Fix |
|---|---|---|---|
| `ping` answers **"General failure"** for every LAN address, **including the router**; internet still works | A VPN client on the *operator* routes `0.0.0.0/0` through the tunnel with a kill-switch (WireGuard "Block untunneled traffic") | `Get-NetRoute` shows `0.0.0.0/0` on the tunnel with metric 0; gateway unreachable | Untick the kill-switch or narrow `AllowedIPs`; LAN is more specific and wins routing |
| Target answers nothing, no ARP entry | Target on guest Wi-Fi (client isolation) or on another subnet | Its own `ipconfig` shows a different prefix | Cable it or move it to the main SSID; disable Wi-Fi once wired |
| ARP entry exists, ports closed | Firewall profile `Public` on the target | `Get-NetConnectionProfile` | Set the profile to `Private` |
| Setup script "fails" to enable firewall groups | Non-English Windows: `-DisplayGroup 'File and Printer Sharing'` does not exist | `No MSFT_NetFirewallRule objects found` | Use language-independent group IDs: `-Group '@FirewallAPI.dll,-28502'` (file/printer sharing), `-32752` (network discovery), `-28752` (remote desktop) |

Wi-Fi adapters with randomized (locally administered) MACs also show up as
a second, unexpected address on the target; wired is the one to keep.

## 2. Access stack (in the order it should be built)

Run `scripts/playbooks/Enable-RemoteAccess.ps1` once on the target as
administrator. It performs only reversible configuration and prints a
report (edition, addresses, shares, SSH state, disks, SMART health).

1. **SSH with a key, admin token.** OpenSSH Server is an optional Windows
   capability (works on Home editions). Put the operator's public key into
   `C:\ProgramData\ssh\administrators_authorized_keys` with the ACL reset to
   `Administrators:F` and `SYSTEM:F` (sshd refuses the file otherwise) and
   set PowerShell as the default shell. This is the channel for every
   administrative action afterwards; it needs no password and yields a full
   admin token for members of Administrators.
2. **SMB shares with a dedicated local account.** Share each fixed drive
   under its letter. Do not authenticate with the owner's Microsoft account
   (see §3); create a local account for sharing
   (`New-ShareAccount.ps1`) whose password is generated *on the target* and
   returned once over SSH, stored on the operator with `cmdkey` and never
   typed into a command line (PowerShell history persists command text).
   Map drives persistently with `net use X: \\TARGET\D /persistent:yes`.
3. **RDP.** Enabled by the same script on Pro/Enterprise; Home editions
   have no RDP host. Prefer `mstsc /v:192.0.2.51` (or a shortcut with those
   arguments) over an `.rdp` file: opening a file from an unknown publisher
   triggers the "unknown publisher / allow these resources" dialog every
   time.
4. **DHCP reservation** for the target on the router, otherwise every saved
   address (drive mappings, credentials, shortcuts, tasks) breaks after a
   lease change.
5. **Power control**: see [Paired-Power-Management](Paired-Power-Management.md).

## 3. RDP and Microsoft accounts — the failure ladder

Logon failures are diagnosed from the target's Security log, not from the
client message. Read event 4625 and map the sub-status:

| SubStatus | Meaning | What it meant in practice |
|---|---|---|
| `0xC0000064` | user name does not exist | typed the bare local name instead of `MicrosoftAccount\user@example.com` |
| `0xC000006A` | wrong password | see the three causes below |
| `0xC000015B` | logon type not granted | account not in *Remote Desktop Users* / Administrators |

Three distinct causes produced `0xC000006A` for a Microsoft account with
the *correct* current password, and had to be removed one by one:

1. **"Only allow Windows Hello sign-in for Microsoft accounts"** (Settings →
   Sign-in options). Registry evidence:
   `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device\DevicePasswordLessBuildVersion = 2`.
   With it on, every password logon is rejected as a bad password. Set to
   `0` (owner action) or switch the toggle off.
2. **Stale cached password hash.** NLA/NTLM validates against the local SAM
   hash of the connected account, which is updated only by a *local
   password logon*. A machine used with a PIN since installation still
   holds the hash from the day the account was created (`net user <name>`
   → "Password last set" equals the install date). Fix: lock the target,
   choose password instead of PIN once. After that the current password
   works over RDP. `net user <name> <pw>` cannot fix this: it fails with
   system error **8646** ("the system is not authoritative for the
   specified account").
3. **Wrong saved credential picked by mstsc.** A generic
   `Domain:target=192.0.2.51` credential stored for SMB is also used by RDP
   and takes the wrong account. Store the RDP identity separately as
   `cmdkey /generic:TERMSRV/192.0.2.51 /user:MicrosoftAccount\user@example.com`,
   which takes precedence; or force a prompt with `mstsc /prompt`.

Fallback that always works: the dedicated local account from §2 added to
*Remote Desktop Users* and *Administrators* — full control, but a separate
profile.

## 4. Silencing RDP prompts (owner-run, HKCU only)

- Unknown-publisher / resource dialog: `HKCU\Software\Microsoft\Terminal Server Client\LocalDevices`,
  DWORD named after the host, value `0x1CC`.
- Self-signed certificate warning: `HKCU\Software\Microsoft\Terminal Server Client\AuthenticationLevelOverride = 0`.
- Launch via `mstsc /v:host /f` from a shortcut, not via an `.rdp` file.

## 5. Verification

- `ssh host 'whoami; ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(544)'` → `True`.
- `net view \\host` lists the shares; `Get-SmbMapping` shows `OK`.
- `qwinsta` on the target shows the operator's session as `Active` on
  `rdp-tcp#N`; Security event 4624 type 10 from the operator's address.

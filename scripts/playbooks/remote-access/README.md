# remote-access/

Turn a Windows machine on the LAN into one you administer from another
machine. Case: [Remote-Windows-Machine-Access](../../../docs/playbooks/Remote-Windows-Machine-Access.md).
All scripts run **on the target, as administrator**; each is a reversible
configuration step with its rollback in the header comment.

Order that worked:

| # | Script | What it does |
|---|---|---|
| 1 | [Set-PrivateNetworkProfile.ps1](Set-PrivateNetworkProfile.ps1) | Every connected network → `Private`, otherwise the firewall drops everything below |
| 2 | [Enable-FirewallGroups.ps1](Enable-FirewallGroups.ps1) | File sharing, network discovery, remote desktop — by `@FirewallAPI.dll` resource ID, so it works on any display language |
| 3 | [Enable-OpenSshServer.ps1](Enable-OpenSshServer.ps1) | OpenSSH Server capability, automatic start, PowerShell as default shell (Home editions included) |
| 4 | [Add-SshAdminKey.ps1](Add-SshAdminKey.ps1) | Operator's public key into `administrators_authorized_keys` with the ACL sshd insists on |
| 5 | [New-ShareAccount.ps1](New-ShareAccount.ps1) | Dedicated local account for SMB (and optionally RDP fallback); password generated here and printed once as the last line so the caller captures it over SSH — never typed on a command line |
| 6 | [New-DriveShares.ps1](New-DriveShares.ps1) | Every fixed drive shared under its letter with full access for one account |
| 7 | [Enable-RemoteDesktop.ps1](Enable-RemoteDesktop.ps1) | RDP host + firewall group on Pro/Enterprise; says so and stops on Home |
| 8 | [Set-NoSleepOnAc.ps1](Set-NoSleepOnAc.ps1) | No unattended sleep/hibernate on AC (coordinated sleep lives in [power/](../power/README.md)) |
| 9 | [Show-RemoteAccessReport.ps1](Show-RemoteAccessReport.ps1) | Read-only summary: edition, adapters, addresses, profiles, shares, sshd/RDP, the Hello-only flag that silently breaks RDP passwords, volumes, disk health |

On the operator side: `ssh-keygen -t ed25519`, a `Host` entry in
`~/.ssh/config` with `BatchMode`/`StrictHostKeyChecking accept-new`,
`cmdkey /add:<host> /user:<host>\share /pass:<captured>` for SMB and
`cmdkey /generic:TERMSRV/<host> /user:<rdp identity>` for RDP,
`net use X: \\<host>\D /persistent:yes`.

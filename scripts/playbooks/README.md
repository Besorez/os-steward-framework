# Playbook scripts

Small, single-purpose PowerShell scripts that back the cases in
[docs/playbooks](../../docs/playbooks/README.md). One script = one action,
grouped by topic; every script has `Get-Help`-style header comments with
purpose, parameters, an example and (for configuration scripts) the
rollback. Nothing here deletes data (OSF-INV-001); scripts either observe
or make a reversible change.

Conventions: ASCII-only (Windows PowerShell 5.1 on non-English systems
reads BOM-less files in the ANSI code page); parameters instead of
constants; examples use RFC-5737 addresses; state and logs go to
`%ProgramData%\OSSteward-playbooks` (machine-wide) or
`%LOCALAPPDATA%\OSSteward-playbooks` (per user), never into the repository.

| Group | Scripts | Playbook |
|---|---|---|
| [network/](network/README.md) | LAN sweep, Wake-on-LAN | [Remote-Windows-Machine-Access](../../docs/playbooks/Remote-Windows-Machine-Access.md), [Paired-Power-Management](../../docs/playbooks/Paired-Power-Management.md) |
| [remote-access/](remote-access/README.md) | network profile, firewall groups by ID, OpenSSH server, SSH admin key, drive shares, share account, RDP host, no-sleep, report | [Remote-Windows-Machine-Access](../../docs/playbooks/Remote-Windows-Machine-Access.md) |
| [storage/](storage/README.md) | volume summary, folder sizes, junk folders, large files, installed apps, engine folders, build-artefact and cache candidates (dry runs) | [Dev-Machine-Storage-Cleanup](../../docs/playbooks/Dev-Machine-Storage-Cleanup.md) |
| [power/](power/README.md) | suspend, sleep watchdog, sleep/wake peer, task installers, NIC wake arming | [Paired-Power-Management](../../docs/playbooks/Paired-Power-Management.md) |

Run any script with `-?` for its help block, e.g.
`powershell -NoProfile -File scripts\playbooks\storage\Get-FolderSizes.ps1 -?`.

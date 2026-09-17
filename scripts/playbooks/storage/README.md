# storage/

Inventory and dry-run proposals for reclaiming space. Every script here is
**read-only**; removal is an owner action outside the framework
(OSF-INV-001). Case: [Dev-Machine-Storage-Cleanup](../../../docs/playbooks/Dev-Machine-Storage-Cleanup.md).

| Script | Answers | Example |
|---|---|---|
| [Get-VolumeSummary.ps1](Get-VolumeSummary.ps1) | How full is each volume; hiberfil/pagefile, recycle bins, update cache, real WinSxS size | `.\Get-VolumeSummary.ps1` |
| [Get-FolderSizes.ps1](Get-FolderSizes.ps1) | Where the space is: folder tree by size, junction-safe, to a depth | `.\Get-FolderSizes.ps1 -Path D:\ -MaxDepth 4 -MinGB 1` |
| [Get-JunkFolders.ps1](Get-JunkFolders.ps1) | Which folders are regenerable by name (Intermediate, DerivedDataCache, node_modules, caches, …) | `.\Get-JunkFolders.ps1 -Roots C:\, D:\ -MinMB 200` |
| [Get-LargeFiles.ps1](Get-LargeFiles.ps1) | The biggest single files with dates (zips next to unpacked copies, old build packages) | `.\Get-LargeFiles.ps1 -Roots D:\, F:\ -MinGB 2` |
| [Get-InstalledApps.ps1](Get-InstalledApps.ps1) | What is installed and how big; the "what survives a reinstall" list | `.\Get-InstalledApps.ps1 -Top 40 \| Format-Table` |
| [Get-EngineFolders.ps1](Get-EngineFolders.ps1) | Unreal engine folders: source checkout vs. engine copied inside a project, with siblings | `.\Get-EngineFolders.ps1 -Roots D:\, S:\ -Exclude 'S:\UE_Vanilla\*'` |
| [Get-BuildArtifactCandidates.ps1](Get-BuildArtifactCandidates.ps1) | **Proposal**: tier-1 build artefacts under project roots (Intermediate, .vs, DerivedDataCache, safe `Saved\*`), collapsed, with total | `.\Get-BuildArtifactCandidates.ps1 -Roots S:\Projects` |
| [Get-CacheCandidates.ps1](Get-CacheCandidates.ps1) | **Proposal**: system-drive caches whose contents regenerate (temp, GPU shader caches, VS Installer cache, update payloads, browser caches) | `.\Get-CacheCandidates.ps1` |

Typical run over SSH for a whole machine: `Get-VolumeSummary`, then
`Get-FolderSizes` per volume, then the two candidate scripts; total wall
time ~30 min for 3–4 TB of small files. Run long scans inside the SSH
session with the client backgrounded, not detached with `Start-Process`
(see [Remote-PowerShell-Gotchas](../../../docs/playbooks/Remote-PowerShell-Gotchas.md)).

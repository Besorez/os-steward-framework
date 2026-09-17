# Playbook: Dev-Machine Storage Cleanup

> **Status: Current** (field-verified 2026-09 on a game-development
> workstation: Unreal Engine projects, Visual Studio, Steam, DAW). Figures
> below are rounded examples from that case, kept only to show the shape of
> the outcome.

## Goal

Reclaim space on a machine full of build output without touching source,
assets, configuration or personal files — and make every removal an
explicit owner decision.

## 1. Inventory first, decisions second

`scripts/playbooks/Get-DiskUsageReport.ps1` (read-only, runs unattended
over SSH, ~30 min for 3–4 TB of small files) produces one text report:

- volumes with used/free;
- system files (hiberfil, pagefile), recycle bins, Windows Update cache,
  WinSxS real size;
- installed applications with estimated sizes (largest first, then all);
- per volume, every folder ≥ 1 GB down to depth 4, indented as a tree;
- **junk candidates**: folders whose *name* marks them as regenerable
  (`Intermediate`, `DerivedDataCache`, `Binaries`, `Saved`, `.vs`,
  `node_modules`, `Library`, caches, `Windows.old`, …) with sizes;
- files ≥ 2 GB with dates.

Two measurement traps:

- **Junctions double count.** `AppData\Local\Application Data`,
  `Local Settings`, `Application Data` in the profile are legacy junctions
  that point back into the profile. Size with
  `Get-ChildItem -Attributes !ReparsePoint` or skip reparse points in the
  walk, otherwise `AppData\Local` reports ~1.6× its real size.
- **`Get-ChildItem -Depth`** counts from the given root: depth 3 from
  `D:\` reaches `D:\a\b\c\` only. Engine roots nested deeper are missed.

## 2. Artefact taxonomy (Unreal Engine / Visual Studio machines)

| Tier | What | Comes back how | Decision |
|---|---|---|---|
| **1 — safe, regenerable** | `Intermediate`, `.vs`, `DerivedDataCache`, `Saved\StagedBuilds`, `Saved\Cooked`, `Saved\Logs`, `Saved\Crashes`, `Saved\Backup`; engine `Cache`, `Zen\Data\cache`; Temp | next build / cook / editor start | remove without discussion (after dry run) |
| **1 — keep inside Saved** | `Saved\Config`, `Saved\Autosaves`, `Saved\SaveGames` | never | keep — user state lives here |
| **2 — regenerable but costly** | project `Binaries`; `Engine\Binaries` and `Engine\DerivedDataCache` of *source-built* engines living inside project folders | full compile, hours for a custom engine | separate owner decision |
| **3 — owner decisions** | whole obsolete engine checkouts (a source `5.x` tree with its `.git` pack), projects from a previous employer, duplicate build zips next to unpacked builds, game libraries, media collections, cloud-drive mirrors in the profile | re-download / re-clone / cannot | list with sizes, owner picks |
| **installed engines** (`Epic Games\UE_5.x` or a vanilla engine folder) | `Engine\Intermediate` there is regenerable too | | leave installed engines alone unless the owner says otherwise — the launcher expects them intact |

Identify engine roots by `Engine\Build\BatchFiles` existing; distinguish a
source checkout (has `Setup.bat`) from a project folder that merely
contains an `Engine` copy — delete the `Engine` folder only, never the
sibling project.

## 3. Windows system-drive caches (safe tier)

Contents of these folders are recreated on demand; the folders stay:

- `%LOCALAPPDATA%\Temp`, `C:\Windows\Temp`, `%LOCALAPPDATA%\CrashDumps`, `ProgramData\Microsoft\Windows\WER`
- GPU shader caches: `%LOCALAPPDATA%\NVIDIA\DXCache|GLCache|OptixCache`, `AppData\LocalLow\NVIDIA` (several GB on a UE machine), `ProgramData\NVIDIA Corporation\Downloader`
- package caches: `%LOCALAPPDATA%\npm-cache`, `NuGet\v3-cache`; `ProgramData\Microsoft\VisualStudio\Packages` (VS Installer download cache, ~10 GB, re-downloaded on modify/repair)
- update payloads: `Microsoft Office\Updates\Download`, `C:\Windows\SoftwareDistribution\Download`, Delivery Optimization (`Delete-DeliveryOptimizationCache`)
- browser `Cache` / `Code Cache`, chat-client caches, Steam `appcache\librarycache`
- `Dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase` — often
  yields little on a recently serviced image; still cheap.

Hibernation and page files belong to the owner's power design, not to a
cleanup.

## 4. Removal is an owner action

The framework never deletes (OSF-INV-001). The pattern that worked:

1. `Get-CleanupCandidates.ps1` prints the exact target list with sizes and
   a total — this is the *proposal* (targets, expected result, and the
   honest statement that deletion is irreversible; the "rollback" is that
   everything in tier 1 regenerates on the next build).
2. The owner approves the list (or edits roots/exclusions) and executes the
   removal with their own command outside the framework.
3. Verify with the free-space delta per volume and a re-run of the
   candidates script (expected: empty).

Uninstalling large applications (an IDE, a game client with libraries on
several drives) follows the same shape: dry-run listing → owner approval →
the vendor's quiet uninstaller (`setup.exe uninstall --installPath … --quiet`
for Visual Studio, `uninstall.exe /S` for Steam) → removal of leftovers →
verification. Stop the application's processes first.

## 5. Outcome shape (example)

| Step | Freed |
|---|---|
| Tier 1 across four volumes (1,467 folders) | ~500 GB |
| Two source-built engines inside old projects | ~130 GB |
| IDE + game client + caches on the system drive | ~85 GB |

System drive went from 13 % free to 52 % free; nothing had to be
reinstalled to keep working. The remaining candidates were all tier 3.

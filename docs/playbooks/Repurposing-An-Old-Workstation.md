# Playbook: Repurposing an Old Workstation

> **Status: Current** (decision guide distilled from a 2026-09 case: a
> many-core Xeon workstation with ECC memory, a mid-range GPU and ~6 TB of
> mixed SSD/HDD, previously a daily driver, now wired to the home LAN next
> to a newer primary machine).

## 1. Decide the role before deciding the OS

Ask what the hardware is *good at* that the primary machine is not. A
workstation-class box wasted on "backup target" is the common mistake; a
backup target is a side effect of any of the roles below, not a role.

| Role | What it needs | Fit for this class of hardware |
|---|---|---|
| Build / cook host (Unreal, large C++), shared DerivedDataCache, CI runner | cores, RAM, fast scratch SSD | excellent — offloads the hours-long jobs from the primary |
| Dedicated game servers for playtests | always-on, CPU, stable address | excellent |
| VM host (one VM per console SDK, Linux services) | RAM, VT-x/VT-d, snapshots | excellent with ≥ 64 GB |
| GPU jobs (local models, transcoding, texture upscaling), game streaming | the GPU | good |
| Storage / archive / backups | the HDD | side effect |
| VPN entry point into the home LAN | always-on, small | side effect |

Decide explicitly whether *development happens on it* or *only builds run
on it*. That single answer determines whether the IDE, SDKs and game
clients stay (they were removed in the case: coding and building moved to
the work machine).

## 2. Disk layout that follows the role

- **System SSD**: OS and services only. Nothing that grows.
- **Fast SSD**: active projects, engines actually in use, DerivedDataCache.
- **Second SSD**: VM images, caches, temporary builds.
- **HDD**: archive, media collections, old releases, backups of the primary.

Move build outputs (`Builds/`, `Releases/`) off SSDs into the archive;
keep a single copy of each build (zip *or* folder, not both).

## 3. OS choice

| Option | When | Notes |
|---|---|---|
| **Hypervisor (Proxmox VE) + Windows VM** | server-first role, several isolated environments wanted | Windows 11 installs *supported* inside the VM via a virtual TPM even on CPUs Windows 11 rejects on bare metal; snapshots before every SDK install; Linux containers for VPN/storage; GPU passthrough possible on workstation boards |
| **Windows 11 Pro bare metal (installer with hardware-check bypass)** | the owner still sits at the machine, wants GPU-native apps, game streaming, DAW | unsupported configuration, updates work in practice, no snapshots |
| **Windows Server** | officially supports old CPUs, RDP host and Hyper-V built in | consumer software and GeForce drivers fight it — poor fit for game/DAW use |

Do not keep an end-of-support client OS (Windows 10 support ended
2025-10) on a box that will be reachable from the internet through a VPN.

A firmware-embedded OEM key (`(Get-CimInstance SoftwareLicensingService).OA3xOriginalProductKey`)
from the original Pro license activates a fresh Pro install or VM — check
it before buying anything.

## 4. VPN choice depends on one fact: is there a public IP?

- **Public (non-CGNAT) address on the router's WAN** → run your own
  WireGuard endpoint at home. One forwarded UDP port, keys you own, no
  third party, direct path. On Windows the server side needs manual NAT/
  routing; in a Linux container (`wg-easy`) it is a web panel and a QR code
  per device. RDP/SMB/SSH are never exposed directly — only the VPN port.
- **CGNAT or dynamic address** → overlay network (ZeroTier, Tailscale):
  peer-to-peer WireGuard-class tunnels brokered by a coordinator, no port
  forwarding, devices admitted one by one in a web panel. Good enough for
  a household; replaceable by the first option when a public IP appears.
- Playtesters do not need the VPN: forward the game server's port for the
  duration of the test, then close it.

On the operator's machine, a work VPN with `AllowedIPs 0.0.0.0/0` and a
kill-switch will block the *entire* home LAN (see
[Remote-Windows-Machine-Access](Remote-Windows-Machine-Access.md) §1);
split-tunnel it or disable the kill-switch.

## 5. Pre-wipe checklist

1. Storage cleanup first ([Dev-Machine-Storage-Cleanup](Dev-Machine-Storage-Cleanup.md)) —
   the same inventory tells you what must survive.
2. Copy the user profile's real content (Documents, Desktop, Pictures,
   `.ssh`, application settings in `AppData\Roaming`) to the archive drive
   with `robocopy /E /COPY:DAT /R:1 /W:1`.
3. Export the installed-application list (`Get-DiskUsageReport.ps1` already
   contains it) and turn the keepers into a `winget install` script.
4. Cloud-drive mirrors in the profile (iCloud Drive, OneDrive) are copies;
   disable sync rather than backing them up.
5. Game libraries re-download; DAW licenses live in vendor accounts;
   engine installs re-download from the launcher. None of these need
   backup.
6. Record the firmware OEM key, TPM presence/version, UEFI/Secure Boot
   state and whether VT-x/VT-d is enabled — they decide §3.
7. Only the system drive is reinstalled; data volumes are untouched and
   reattached.

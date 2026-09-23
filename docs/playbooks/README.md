# Playbooks

> **Status: Current.** Field-verified operational knowledge. Each playbook
> records a real stewardship case in generalized form: the symptom, the
> evidence that identified the cause, the approach that worked, and the
> traps met on the way. Nothing here is architecture; the invariants in the
> [Constitution](../architecture/Constitution.md) still govern everything.

## Rules for a playbook

- **Generic, never machine-specific** (OSF-INV-008). Examples use RFC-5737
  addresses (`192.0.2.0/24`), placeholder host names and `TestUser`. No
  MAC addresses, no inventories, no logs.
- **Evidence first** (OSF-INV-006). A playbook names the exact signal
  (event ID, error code, counter, exit code) that distinguishes the cause
  from look-alikes.
- **Read-only or reversible artifacts only.** Scripts under
  `scripts/playbooks/` observe, report, or make reversible changes (sleep,
  wake, configuration with a known rollback). Removal of data is never a
  script in this repository (OSF-INV-001/002): a playbook may describe how
  the owner performs it, always as *dry run → explicit target list →
  explicit approval → owner-executed removal → verification* — the shape of
  the Action Proposal flow from the
  [Safety Model](../security/Safety-Model.md), executed by the owner.
- **English source of truth** (OSF-INV-013); the interaction that produced
  the case may have been in any language.

## Index

| Playbook | Case |
|---|---|
| [Remote-Windows-Machine-Access](Remote-Windows-Machine-Access.md) | Reaching and administering a second Windows machine on the same LAN: discovery, the blockers that hide it, SSH/SMB/RDP setup, Microsoft-account RDP failures, prompt suppression |
| [Dev-Machine-Storage-Cleanup](Dev-Machine-Storage-Cleanup.md) | Reclaiming space on a game-development machine: inventory method, artefact taxonomy (Unreal, Visual Studio, caches), tiered decisions, owner-executed removal |
| [Paired-Power-Management](Paired-Power-Management.md) | Making a secondary machine sleep and wake together with the primary one: Wake-on-LAN, sleep on event, watchdog with an opt-out sentinel; fixing the wake / idle-sleep ping-pong (pattern wake + hidden unattended timeout) |
| [Repurposing-An-Old-Workstation](Repurposing-An-Old-Workstation.md) | Deciding what an old workstation becomes (build host, storage, VPN entry, VM host), disk layout, OS choice, VPN choice, pre-wipe checklist |
| [Remote-PowerShell-Gotchas](Remote-PowerShell-Gotchas.md) | Traps met when driving Windows over SSH with Windows PowerShell 5.1: encoding, quoting, localized names, junction double counting, sessions dropped by NIC changes |

## Scripts

The scripts behind the playbooks live in
[`scripts/playbooks/`](../../scripts/playbooks/README.md), one small script
per action, grouped by topic, each with a README that maps scripts to
playbook sections:

| Group | Contents |
|---|---|
| [network/](../../scripts/playbooks/network/README.md) | LAN sweep with port probe; Wake-on-LAN |
| [remote-access/](../../scripts/playbooks/remote-access/README.md) | Nine reversible steps from "invisible box" to SSH + SMB + RDP, plus a read-only report |
| [storage/](../../scripts/playbooks/storage/README.md) | Eight read-only inventory scripts, including the two dry-run *proposal* generators (build artefacts, caches) |
| [power/](../../scripts/playbooks/power/README.md) | Suspend, watchdog, peer sleep/wake wrappers, task installers, NIC wake arming |

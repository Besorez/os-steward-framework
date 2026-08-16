# Baseline Model

> **Status: Prototype.** What exists today is deterministic snapshot
> comparison; a learned "normal for this machine" baseline is Planned.
> Code owner: `src/OsSteward.Core/Snapshots/SnapshotComparer.cs`.

## What is implemented — snapshot diff

`os_baseline_compare` compares the **current live state** of a category
against a stored snapshot (latest by default) and reports:

- **added** — items present now, absent in the reference
- **removed** — items in the reference, absent now
- **changed** — same identity, different tracked fields

Item identity keys:

| Category | Key | Changed-field detection |
|---|---|---|
| processes | `name \| executablePath` | presence only (a restarted process is not a "change") |
| startup | `location \| name` | `command` |

Duplicate keys collapse to first occurrence. The comparer detects deviation
only — it never judges whether a change is good, bad, or malicious
(collectors collect, detectors detect, reasoning concludes).

## What is deliberately NOT claimed

One snapshot is not "normal" (§18). A single reference cannot express
periodic processes, update churn, or usage patterns. Until multi-snapshot
baselines exist, findings based on a diff must carry appropriately limited
confidence.

## Planned

- Multi-snapshot baselines with observation counts and first/last-seen
  timestamps, stored under `<runtime>/state/baselines/`.
- Baseline components per §18: processes, services, drivers, startup,
  tasks, software, listeners, resource patterns, boot performance, hashes,
  signatures, parent/child relationships, storage distribution.
- Versioned baseline format from the first implementation.

# Snapshot Model

> **Status: Current** for `processes` and `startup`; other categories
> Planned. Code owner: `src/OsSteward.Core/Snapshots/Snapshot.cs`,
> store: `src/OsSteward.State/SnapshotStore.cs`.

A snapshot is machine state of one category captured at a point in time.

```jsonc
{
  "schemaVersion": 1,
  "category": "processes",          // "processes" | "startup" (more planned)
  "snapshotId": "20260816-130028-884",  // UTC yyyyMMdd-HHmmss-fff
  "createdAt": "2026-08-16T13:00:28.884+00:00",
  "items": [ /* category-specific normalized records */ ]
}
```

- **Storage**: `<runtime>/state/snapshots/<category>/<snapshotId>.json`,
  raw (unredacted) — snapshots never leave local storage. The store is
  append-only: no delete capability exists (OSF-INV-001).
- **Creation**: `os_snapshot_create` (the only Level-0 tool that writes —
  a local state file, not system state).
- **Versioning**: `schemaVersion` is bumped on breaking item-shape changes;
  loaders must treat unknown versions explicitly, never guess.
- **Planned categories** (§19): services, drivers, tasks, network,
  performance, storage, software, security.
- Real snapshots never enter Git; repository fixtures
  (`tests/fixtures/*.json`) are synthetic and use `TestUser` identities.

Comparison semantics live in [Baseline-Model.md](Baseline-Model.md).

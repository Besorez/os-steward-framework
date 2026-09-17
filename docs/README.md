# OS Steward Documentation

Navigation hub. One concept = one canonical document; start with
[STATUS.md](STATUS.md) for what is real today.

## Map

- **[STATUS.md](STATUS.md)** — live status board: implemented / ready next /
  planned / blocked
- **architecture/** — [README](architecture/README.md)
  - [Constitution.md](architecture/Constitution.md) — the invariants
    (OSF-INV-001…014) and permission levels. Read this first.
  - [System-Overview.md](architecture/System-Overview.md) — layers,
    repository layout, key mechanics
  - [Mcp-Tools.md](architecture/Mcp-Tools.md) — MCP tool contract catalog
  - [decisions/](architecture/decisions/) — ADR-0001…0006
- **concepts/**
  - [Snapshot-Model.md](concepts/Snapshot-Model.md)
  - [Baseline-Model.md](concepts/Baseline-Model.md)
  - [Finding-Model.md](concepts/Finding-Model.md)
- **privacy/** — [Privacy-Model.md](privacy/Privacy-Model.md) — runtime
  isolation, redaction, Git protection, safe export (canonical privacy doc)
- **security/** — [Safety-Model.md](security/Safety-Model.md) — structural
  guarantees, safety hook, error honesty, ActionProposal design (canonical
  safety doc)
- **playbooks/** — [README](playbooks/README.md) — field-verified
  stewardship cases in generalized form (remote machine access, storage
  cleanup, paired power management, repurposing a workstation, remote
  PowerShell gotchas), each backed by small scripts under
  [`scripts/playbooks/`](../scripts/playbooks/README.md)

## Conventions

Every document declares a design status: **Current** (implemented as
described), **Designed** (specified, not implemented), **Prototype**
(partial), **Planned** (intent only), **Deprecated**. Future ideas are never
documented as existing architecture.

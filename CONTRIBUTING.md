# Contributing to OS Steward

Thank you for considering a contribution. OS Steward has an unusual
constraint set: it is a framework an AI agent operates, so **safety and
privacy rules are architecture, not etiquette**. Read these first:

- [Architecture Constitution](docs/architecture/Constitution.md) — the
  project invariants (OSF-INV-001…014)
- [Privacy Model](docs/privacy/Privacy-Model.md)
- [Safety Model](docs/security/Safety-Model.md)

## Non-negotiables

A pull request is rejected regardless of quality if it:

- adds any deletion or destructive capability to the tool API (OSF-INV-001/002);
- adds a system-modifying capability without the Action Proposal flow and
  explicit-confirmation lifecycle (OSF-INV-004/005);
- weakens the privacy guard, redaction, or runtime isolation;
- introduces a generic "execute arbitrary command" tool;
- commits machine-specific data of any kind (OSF-INV-008) — fixtures must be
  synthetic (`TestUser`, `TESTBOX-01`, RFC-5737 IPs);
- adds non-English source, comments, identifiers, or docs (OSF-INV-013).

Changing an invariant itself requires an explicit project-owner decision via
the Change Review procedure in the Constitution.

## Development setup

Windows + .NET 10 SDK.

```powershell
powershell -File scripts/install-git-hooks.ps1   # enable the pre-commit privacy guard (required)
dotnet build
dotnet test
```

The privacy guard blocks commits containing likely private machine data. If
it flags a genuine synthetic fixture, add a *narrow, reviewed* entry to
`scripts/privacy-guard-allowlist.json` (path + explicit categories + reason)
in the same PR — never disable the guard.

## Expectations for changes

- **Tests**: new behavior comes with tests; safety- and privacy-relevant
  changes come with tests proving the protection still holds
  (see `GuardScriptTests`, `RedactorTests` for patterns).
- **Error honesty**: never convert "access denied" into "no data" — use the
  explicit `ErrorKind` values and `unavailableFields`.
- **Tool design**: narrow, typed, predictable. Every MCP tool returns the
  `ToolResult` envelope and passes through `ToolEnvelope` redaction.
- **Docs**: one concept = one canonical document; update the owner document
  instead of duplicating rules. Update `docs/STATUS.md` when a capability's
  status changes.
- **Commits**: focused and reviewable; no generated runtime state, no
  diagnostic output, no scratch artifacts.

## AI-assisted development

This repository is developed with Claude Code. If you use an AI agent:

- the agent must not commit, push, or modify Git history without your
  explicit per-action approval;
- the safety hook (`hooks/safety-guard.ps1`) and privacy guard must stay
  enabled;
- treat agent-proposed invariant changes as owner decisions, not defaults.

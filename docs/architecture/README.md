# Architecture Documentation

- [Constitution.md](Constitution.md) — **canonical invariants**
  (OSF-INV-001…014), permission levels, change-review procedure. Everything
  else conforms to this document.
- [System-Overview.md](System-Overview.md) — layered flow, project/repo
  layout, reserved directories, key mechanics.
- [Mcp-Tools.md](Mcp-Tools.md) — the MCP tool surface: envelope contract,
  per-tool catalog, evolution rules.
- [decisions/](decisions/) — architecture decision records:
  - [ADR-0001](decisions/ADR-0001-runtime-data-outside-repository.md) runtime data outside the repository
  - [ADR-0002](decisions/ADR-0002-read-only-default.md) read-only default
  - [ADR-0003](decisions/ADR-0003-no-destructive-tool-api.md) no destructive tool API
  - [ADR-0004](decisions/ADR-0004-english-canonical-repository.md) English canonical repository
  - [ADR-0005](decisions/ADR-0005-configurable-interaction-language.md) configurable interaction language
  - [ADR-0006](decisions/ADR-0006-dotnet-stack.md) C#/.NET stack

Related canonical documents: [Privacy-Model](../privacy/Privacy-Model.md),
[Safety-Model](../security/Safety-Model.md), concept models in
[../concepts/](../concepts/).

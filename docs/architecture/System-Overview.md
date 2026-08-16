# System Overview

> **Status: Current** unless a section says otherwise. Invariants live in
> [Constitution.md](Constitution.md); this document describes the shape of
> the implementation.

## Layered flow

```text
Claude Code
  ├── skills/    HOW to investigate (procedures, evidence rules)
  ├── hooks/     deterministic safety guard (PreToolUse, fail-closed)
  └── MCP stdio ─► OsSteward.Mcp     typed os_* tool surface + ToolEnvelope redaction
                    │
                    ├── OsSteward.Platform.Windows   collectors: collect + normalize only
                    ├── OsSteward.State              %LOCALAPPDATA%\OSSteward (snapshots, prefs)
                    ├── OsSteward.Privacy            Redactor
                    └── OsSteward.Core               ToolResult, Snapshot(+Comparer),
                                                     Finding, telemetry records, OsJson
```

Dependency direction: `Mcp → {Platform.Windows, State, Privacy} → Core`.
Core is platform-neutral — no Windows types leak into it (§30). Collectors
never classify; comparison never judges; conclusions belong to the
reasoning layer under OSF-INV-006.

## Repository layout

```text
.claude-plugin/   plugin manifest (MCP server, distributed components)
.claude/          project dev settings (safety hook for this repo's sessions)
.githooks/        pre-commit → privacy guard
skills/           investigate-slowdown (more per §12: incremental addition)
hooks/            safety-guard.ps1 + hooks.json
scripts/          privacy-guard.ps1 (+allowlist), install-git-hooks.ps1
src/              five C# projects (above)
tests/            four xUnit projects + tests/fixtures (synthetic only)
docs/             this documentation tree; STATUS.md is the live status board
```

Reserved (documented here, intentionally not created empty): `agents/`
(specialized agents only when justified, §13), `policies/` (Level-2 action
policies — no actions exist yet), `src/*/detectors/`, `mcp/` server-neutral
contract space beyond [Mcp-Tools.md](Mcp-Tools.md), `.local/`, `.workspace/`,
`.temp/`, `artifacts/local|runtime|generated/` (ignored dev scratch, §9).

## Key mechanics

- **Tool output contract**: every tool returns a redacted, serialized
  `ToolResult` (see [Mcp-Tools.md](Mcp-Tools.md)). Failures are explicit
  (`ErrorKind`); partial reads surface as `warnings`/`unavailableFields`.
- **Runtime isolation**: `RuntimePaths` (override → `OSSTEWARD_HOME` →
  `%LOCALAPPDATA%\OSSteward`); see ADR-0001.
- **Guards**: structural no-destructive-API (ADR-0003) + safety hook +
  privacy guard, each with deterministic self-tests wired into `dotnet test`.
- **Naming**: canonical capability names use dots (`os.process.list`); MCP
  tool names use underscores (`os_process_list`) because the MCP tool-name
  charset excludes dots.

## Decision records

[ADR index](decisions/): 0001 runtime data outside repo · 0002 read-only
default · 0003 no destructive tool API · 0004 English canonical repo ·
0005 configurable interaction language · 0006 C#/.NET stack.

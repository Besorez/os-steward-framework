# OS Steward

**A privacy-first, local-first, AI-assisted operating-system stewardship
framework.** Claude investigates your Windows machine's behavior through
narrow, typed, read-only tools — collects evidence, explains likely causes,
and recommends safe next steps. It does not act as an unrestricted shell.

```text
Operating System → Collectors → Normalized telemetry → Local state
→ Claude reasoning → Evidence-backed findings → Recommendations
```

## What it will never do

- **Never delete** anything (no deletion capability exists in the tool API)
- **Never modify the system silently** — V0.1 has no modification
  capability at all; future reversible actions will require explicit
  per-action approval
- **Never put machine data in Git** — all telemetry and state live in
  `%LOCALAPPDATA%\OSSteward\`, and a deterministic pre-commit guard blocks
  private data from being committed
- **Never upload telemetry** — local-first by default
- **Never conclude without evidence** — "insufficient evidence" is a valid
  answer; fabricated certainty is not

Canonical rules: [docs/architecture/Constitution.md](docs/architecture/Constitution.md) ·
[Privacy Model](docs/privacy/Privacy-Model.md) ·
[Safety Model](docs/security/Safety-Model.md) ·
[Status](docs/STATUS.md)

## Status: V0.1 — Read-Only Foundation (early)

Implemented and tested (see [STATUS](docs/STATUS.md) for the full table):

- **MCP server** (.NET 10, [ModelContextProtocol](https://www.nuget.org/packages/ModelContextProtocol) SDK, stdio) with 9 typed tools:
  `os_process_list`, `os_process_inspect`, `os_process_tree`,
  `os_performance_snapshot`, `os_startup_list`, `os_snapshot_create`,
  `os_baseline_compare`, `os_config_get`, `os_config_set`
- **Windows collectors**: processes (WMI + Authenticode signature + SHA-256),
  performance (CPU sampling, memory, disk counters), startup (registry +
  folders) — read-only, with explicit per-field error reporting
- **Redaction layer**: every tool response is scrubbed of usernames, machine
  names, and user-profile paths before it reaches the model
- **Safety hook**: deterministic PreToolUse blocker for destructive shell
  commands (fail-closed)
- **Git privacy guard**: pre-commit scanner that blocks commits containing
  likely private machine data
- **Skill** `investigate-slowdown`: evidence-driven answer to
  *"Why is my computer slow?"*
- **Language**: responds in `auto` / `en` / `uk` (preference stored locally);
  all internal schemas stay English

Everything else (more collectors, detectors, learned baselines, findings
persistence, safe export, any modification capability) is **planned, not
implemented** — see [STATUS](docs/STATUS.md).

## Quick start (development)

Requirements: Windows, .NET 10 SDK.

```powershell
# enable the pre-commit privacy guard (once per clone)
powershell -File scripts/install-git-hooks.ps1

dotnet build
dotnet test
```

Claude Code integration: the repository is a Claude Code plugin
(`.claude-plugin/plugin.json`) exposing the MCP server, the safety hook, and
the skill. Ask *"Why is my computer slow?"* and the `investigate-slowdown`
skill drives a read-only, evidence-based investigation.

## License

Apache-2.0 — see [LICENSE](LICENSE).

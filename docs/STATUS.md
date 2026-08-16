# Project Status

Current milestone: **V0.1 — Read-Only Foundation**

Last updated: 2026-08-16

## Implemented (code exists, tests pass)

| Capability | Where | Notes |
|---|---|---|
| Architecture constitution | `docs/architecture/Constitution.md` | Canonical invariants OSF-INV-001…014 |
| Defensive `.gitignore` + `.gitattributes` | repo root | |
| Git privacy guard (pre-commit) | `scripts/privacy-guard.ps1`, `.githooks/` | Self-tested; blocked a real leak during development |
| Safety hook (destructive-command blocker) | `hooks/safety-guard.ps1`, `hooks/hooks.json`, `.claude/settings.json` | Fail-closed, self-tested |
| Core domain schemas | `src/OsSteward.Core` | ToolResult, Snapshot, SnapshotComparer, Finding, telemetry records |
| Redaction layer | `src/OsSteward.Privacy` | Verified in smoke + live runs: zero identifier leaks |
| Local runtime state | `src/OsSteward.State` | `%LOCALAPPDATA%\OSSteward`, `OSSTEWARD_HOME` override, snapshot + preferences stores |
| Windows collectors | `src/OsSteward.Platform.Windows` | Process (WMI), performance (sampling + counters), startup (registry + folders), Authenticode, SHA-256 |
| MCP server, 9 tools | `src/OsSteward.Mcp` | ModelContextProtocol 2.2.0, stdio; contract: `docs/architecture/Mcp-Tools.md` |
| Live scenario verification | — | 2026-08-16: full "why is my computer slow" flow on real machine — perf snapshot → inspect (signed binary, sha256, ancestry) → snapshots (313 procs / 13 startup) → compare → honest invalidRequest; redaction PASS |
| Claude plugin manifest | `.claude-plugin/plugin.json` | |
| Skill: investigate-slowdown | `skills/investigate-slowdown/SKILL.md` | Primary V0.1 scenario (§47) |
| Tests | `tests/` | 30 xUnit tests + 42 guard self-test cases, all passing |
| Language preference (auto/en/uk) | `os_config_get` / `os_config_set` + skill instructions | |
| Documentation set | `docs/` + root | README (§34 structure), SECURITY, CONTRIBUTING, CHANGELOG, System-Overview, Mcp-Tools, ADR-0001…0006, concept docs (Snapshot/Baseline/Finding), navigation hubs, GitHub issue/PR templates |

## Ready Next

- Live plugin session test: install the plugin into Claude Code and drive
  the skill conversationally (server + tools already verified end-to-end
  via stdio driver)
- Windows collector smoke tests (live-machine xUnit tests for process /
  performance / startup collectors)
- CI workflow (`.github/workflows/`): build + test + guard self-tests on
  push/PR
- Services collector (`os.service.list` / `os.service.inspect`) — the next
  telemetry increment per the critical path

## Planned Later

- Detectors (beyond snapshot diff); multi-snapshot learned baselines;
  history diff
- Drivers / scheduled tasks / network / storage / events collectors
- Finding persistence + investigation trace (§43)
- Safe export pipeline (redaction → secret scan → sanitized artifact)
- Performance history (persistent sampler)
- Level 2 Action Proposal implementation (design in Safety-Model.md)
- Plugin marketplace packaging; published single-file exe for the MCP server

## Blocked

- Nothing currently blocked.

## Notes for the next session

- Solution file is `OsSteward.slnx` (.NET 10 format). Build: `dotnet build`;
  tests: `dotnet test`.
- MCP smoke/live driver pattern: keep stdin open (piped-EOF drops
  responses); drivers live in the session scratchpad, recreate as needed.
- Pre-commit privacy guard is enabled locally (`core.hooksPath .githooks`).
- Disk performance counters use English names ("PhysicalDisk") — on
  non-English Windows disk activity degrades to an explicit
  `disk:NotAvailable` warning (known limitation, honest failure).

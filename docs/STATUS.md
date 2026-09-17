# Project Status

Current milestone: **V0.1 — Read-Only Foundation**

Last updated: 2026-09-17

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
| MCP server, 11 tools | `src/OsSteward.Mcp` | ModelContextProtocol 2.2.0, stdio; contract: `docs/architecture/Mcp-Tools.md` |
| Services collector + tools | `src/OsSteward.Platform.Windows/ServiceCollector.cs` | `os_service_list` / `os_service_inspect`; snapshot category `services` (config-only diff); live-verified 2026-08-16 (296 services, signature + sha256 on Winmgmt) |
| CI workflow | `.github/workflows/ci.yml` | Build + tests + guard self-tests on windows-latest |
| Project MCP registration + dev skill | `.mcp.json`, `.claude/skills/` | Framework usable conversationally in dev sessions (from next session start) |
| Live scenario verification | — | 2026-08-16: full "why is my computer slow" flow on real machine — perf snapshot → inspect (signed binary, sha256, ancestry) → snapshots (313 procs / 13 startup) → compare → honest invalidRequest; redaction PASS |
| Claude plugin manifest | `.claude-plugin/plugin.json` | |
| Skill: investigate-slowdown | `skills/investigate-slowdown/SKILL.md` | Primary V0.1 scenario (§47) |
| Tests | `tests/` | 30 xUnit tests + 42 guard self-test cases, all passing |
| Language preference (auto/en/uk) | `os_config_get` / `os_config_set` + skill instructions | |
| Documentation set | `docs/` + root | README (§34 structure), SECURITY, CONTRIBUTING, CHANGELOG, System-Overview, Mcp-Tools, ADR-0001…0006, concept docs (Snapshot/Baseline/Finding), navigation hubs, GitHub issue/PR templates |
| Playbooks + scripts | `docs/playbooks/`, `scripts/playbooks/` | Five field-verified cases (2026-09: remote Windows machine access, dev-machine storage cleanup, paired power management, repurposing an old workstation, remote PowerShell gotchas) and 27 small read-only / reversible scripts in four groups with per-group READMEs; no deletion scripts by design (OSF-INV-001) |

## Ready Next

- Conversational session test: restart a Claude Code session in this repo
  (picks up `.mcp.json` + the dev skill) and ask "why is my computer slow"
- Windows collector smoke tests for process / performance / startup
  collectors (services already has live tests)
- Scheduled-tasks collector (`os.task.list`) — next telemetry increment
- Verify the CI workflow's first run on GitHub Actions

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

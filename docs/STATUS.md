# Project Status

Current milestone: **V0.1 — Read-Only Foundation (MVP slice)**

Last updated: 2026-08-15

## Implemented (code exists, tests pass)

| Capability | Where | Notes |
|---|---|---|
| Architecture constitution | `docs/architecture/Constitution.md` | Canonical invariants OSF-INV-001…014 |
| Defensive `.gitignore` + `.gitattributes` | repo root | |
| Git privacy guard (pre-commit) | `scripts/privacy-guard.ps1`, `.githooks/` | Self-tested; enable via `scripts/install-git-hooks.ps1` |
| Safety hook (destructive-command blocker) | `hooks/safety-guard.ps1`, `hooks/hooks.json` | Fail-closed, self-tested |
| Core domain schemas | `src/OsSteward.Core` | ToolResult, Snapshot, SnapshotComparer, Finding, telemetry records |
| Redaction layer | `src/OsSteward.Privacy` | Verified: no username/machine leak in MCP smoke test |
| Local runtime state | `src/OsSteward.State` | `%LOCALAPPDATA%\OSSteward`, `OSSTEWARD_HOME` override, snapshot + preferences stores |
| Windows collectors | `src/OsSteward.Platform.Windows` | Process (WMI), performance (sampling + counters), startup (registry + folders), Authenticode, SHA-256 |
| MCP server, 9 tools | `src/OsSteward.Mcp` | ModelContextProtocol 2.2.0, stdio; smoke-tested end-to-end |
| Claude plugin manifest | `.claude-plugin/plugin.json` | |
| Skill: investigate-slowdown | `skills/investigate-slowdown/SKILL.md` | Primary V0.1 scenario (§47) |
| Tests | `tests/` | 30 xUnit tests + 42 guard self-test cases, all passing |
| Canonical docs | Constitution, Privacy-Model, Safety-Model, this file | |
| Language preference (auto/en/uk) | `os_config_get` / `os_config_set` + skill instructions | |

## Ready Next (deferred from Phase 2 by owner's MVP decision, 2026-08-15)

- ADR-0001…0006 (decisions currently summarized in Constitution + this file:
  runtime data outside repo; read-only default; no destructive tool API;
  English canonical repo; configurable language; C#/.NET 10 stack)
- Concept docs: Snapshot-Model.md, Baseline-Model.md, Finding-Model.md
  (schemas exist in code with XML docs)
- Full product README per §34; SECURITY.md; CONTRIBUTING.md; CHANGELOG.md
- docs/README.md + docs/architecture/README.md navigation hubs;
  System-Overview.md
- mcp/README.md full tool-contract catalog (descriptions currently live in
  tool attributes)
- Windows collector smoke tests (live-machine xUnit tests)
- `.github/` issue/PR templates with raw-data warnings (§63)

## Planned Later

- Detectors (beyond snapshot diff); multi-snapshot baselines; history diff
- Services / drivers / scheduled tasks / network / storage / events collectors
- Finding persistence + investigation trace (§43)
- Safe export pipeline (redaction → secret scan → sanitized artifact)
- Performance history (persistent sampler)
- Level 2 Action Proposal implementation (design in Safety-Model.md)
- Plugin marketplace packaging; published single-file exe for MCP server

## Blocked

- Nothing currently blocked.

## Notes for the next session

- Solution file is `OsSteward.slnx` (.NET 10 format). Build: `dotnet build`;
  tests: `dotnet test`. MCP smoke driver pattern: keep stdin open
  (piped-EOF drops responses).
- Git hooks are NOT yet enabled locally — run
  `scripts/install-git-hooks.ps1` (needs owner action or approval).
- Nothing committed yet; commit proposal pending owner approval.

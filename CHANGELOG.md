# Changelog

All notable changes to OS Steward are documented here. The format is based
on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow
semantic intent (pre-1.0: minor = capability milestone).

## [Unreleased]

### Added
- **Playbooks** (`docs/playbooks/`): field-verified stewardship cases in
  generalized form — remote Windows machine access (discovery blockers,
  SSH/SMB/RDP stack, Microsoft-account RDP failure ladder with Security-log
  evidence), dev-machine storage cleanup (inventory method, artefact
  taxonomy, owner-executed removal pattern), paired power management
  (Wake-on-LAN + sleep on event + watchdog), repurposing an old
  workstation (role, disk layout, OS and VPN choice, pre-wipe checklist),
  remote PowerShell gotchas.
- **Playbook scripts** (`scripts/playbooks/`): 27 small, single-purpose
  PowerShell scripts in four groups (`network`, `remote-access`, `storage`,
  `power`) with a README per group linking back to the playbooks. All are
  read-only or reversible; storage scripts produce dry-run proposals and
  never delete (OSF-INV-001).
- **Services collector** (`ServiceCollector`, WMI Win32_Service) with two
  new MCP tools: `os_service_list`, `os_service_inspect` (description,
  executable resolution for quoted and unquoted-with-spaces command lines,
  Authenticode signature, SHA-256). Snapshot category `services` with
  configuration-only change detection (state flips ignored) via the new
  shared `CategoryComparers`.
- **CI workflow** (`.github/workflows/ci.yml`): Windows build (warnings as
  errors), full test suite, and both guard self-test suites on push/PR.
- **Project MCP registration** (`.mcp.json`) and a dev copy of the
  `investigate-slowdown` skill under `.claude/skills/` so development
  sessions in this repository can drive the framework conversationally.
- Documentation set: full README, SECURITY, CONTRIBUTING, architecture
  decision records (ADR-0001…0006), concept docs (Snapshot, Baseline,
  Finding), System Overview, MCP tool-contract catalog, documentation
  navigation hubs, GitHub issue/PR templates.

## [0.1.0] — 2026-08-15

V0.1 Read-Only Foundation (MVP slice). Commit `853df6c`.

### Added
- **Architecture constitution** — canonical invariants OSF-INV-001…014
  (`docs/architecture/Constitution.md`).
- **Git privacy protection** — defensive `.gitignore`, deterministic
  pre-commit privacy guard with reviewed allowlist and embedded self-tests
  (`scripts/privacy-guard.ps1`).
- **Safety hook** — fail-closed PreToolUse destructive-command blocker for
  Claude Code shell tools (`hooks/safety-guard.ps1`).
- **Core domain** (`OsSteward.Core`) — `ToolResult` envelope with explicit
  error kinds, snapshot schema + deterministic comparer, `Finding` schema,
  normalized telemetry records; canonical camelCase/English JSON settings.
- **Privacy layer** (`OsSteward.Privacy`) — redaction of user-profile paths,
  usernames, and machine names, tolerant of JSON-escaped separators.
- **Local state** (`OsSteward.State`) — runtime root resolution
  (`%LOCALAPPDATA%\OSSteward`, `OSSTEWARD_HOME` override), append-only
  snapshot store, language preferences (`auto`/`en`/`uk`).
- **Windows collectors** (`OsSteward.Platform.Windows`) — processes via WMI
  with Authenticode signature (WinVerifyTrust) and SHA-256; performance via
  two-point CPU sampling, `GlobalMemoryStatusEx`, disk counters; startup via
  registry Run/RunOnce keys and startup folders. Read-only, per-field error
  reporting.
- **MCP server** (`OsSteward.Mcp`, ModelContextProtocol 2.2.0, stdio) with
  nine typed tools: `os_process_list`, `os_process_inspect`,
  `os_process_tree`, `os_performance_snapshot`, `os_startup_list`,
  `os_snapshot_create`, `os_baseline_compare`, `os_config_get`,
  `os_config_set`. All output redacted centrally via `ToolEnvelope`.
- **Claude Code plugin** manifest (`.claude-plugin/plugin.json`) and skill
  `investigate-slowdown` (evidence-driven slowdown investigation, §47
  scenario).
- **Tests** — 30 xUnit tests (schemas, comparer, redaction, state,
  guard-script self-test wrappers) + 42 embedded guard self-test cases;
  synthetic fixtures only.

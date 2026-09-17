# OS Steward

**A privacy-first, local-first, AI-assisted operating-system stewardship
framework for Windows.**

## What OS Steward is

OS Steward lets an AI agent (Claude Code) investigate your machine's
behavior the way a careful engineer would: collect telemetry through
narrow, typed, read-only tools, correlate evidence, explain likely causes,
and recommend safe next steps. The AI is an investigator and reasoning
layer — never an unrestricted shell operator.

```text
Operating System → Collectors → Normalized telemetry → Local state
→ Baselines → Evidence → Claude reasoning → Findings → Recommendations
```

## Why it exists

"Why is my computer slow?", "What changed since yesterday?", "Where did
this process come from?" — answering these requires evidence, not guesses,
and today's answer is usually either a random forum tip or handing an AI
raw admin PowerShell. OS Steward exists to make the investigation rigorous
and the AI's power structurally bounded at the same time.

## Core principles

Canonical: [Architecture Constitution](docs/architecture/Constitution.md)
(OSF-INV-001…014). In short: read-only by default · evidence before
conclusion · local-first · repository stateless · minimum necessary data ·
no hidden actions · least privilege · English source of truth ·
configurable interaction language.

## What it can do (today)

- Answer *"Why is my computer slow?"* via the `investigate-slowdown` skill:
  performance snapshot → top consumers → per-process inspection (command
  line, owner, parent chain, Authenticode signature, SHA-256) → process
  tree → comparison against a stored snapshot → evidence-backed explanation
  with ranked hypotheses.
- Inventory startup entries (registry Run/RunOnce + startup folders) and
  Windows services (state, start mode, account, binary signature and hash
  on inspection).
- Capture local snapshots of processes/startup/services and diff current
  state against them (added / removed / changed; service diffs flag
  configuration changes, not routine state flips).
- Respond in your language (`auto`/`en`/`uk`), keeping all internal
  schemas English.

## Playbooks

Field-verified cases, written up generically so they apply to any machine:
[docs/playbooks](docs/playbooks/README.md) — remote access to a second
Windows machine, storage cleanup on a development box, paired sleep/wake
of two machines, repurposing an old workstation, remote PowerShell traps.
Each is backed by small read-only or reversible scripts under
[scripts/playbooks](scripts/playbooks/README.md), one script per action,
grouped by topic, navigable from here down to the file.

## What it will never do

- **Never delete** anything — no deletion capability exists in the tool API
- **Never modify the system silently** — V0.1 has no modification
  capability at all; any future change requires a per-action proposal with
  impact, risk, rollback, and your explicit approval
- **Never put machine data in Git** — state lives in
  `%LOCALAPPDATA%\OSSteward\`; a deterministic pre-commit guard blocks
  private data from commits
- **Never upload telemetry** — everything stays local by default
- **Never conclude without evidence** — "insufficient evidence" is a valid
  answer; fabricated certainty is not

## Privacy

Three independent layers ([Privacy Model](docs/privacy/Privacy-Model.md)):
physical isolation of all machine state outside the repository; a redaction
layer that scrubs usernames, machine names, and profile paths from every
tool response before the model sees them; and Git protection (defensive
`.gitignore` + a fail-closed pre-commit privacy scanner with a reviewed
allowlist and no global skip flag).

## Safety model

The primary guarantee is structural: the MCP tool surface contains no
destructive or system-modifying capability, so unsafe behavior is
impossible through the framework regardless of prompts. A deterministic
PreToolUse hook additionally blocks destructive shell commands
(fail-closed). Errors are honest: "access denied" is never reported as "no
anomaly". Details: [Safety Model](docs/security/Safety-Model.md).

## Architecture

```text
Claude Code → skills / hooks / MCP (stdio)
  OsSteward.Mcp                typed os_* tools + central redaction
  OsSteward.Platform.Windows   collectors (WMI, WinVerifyTrust, counters, registry)
  OsSteward.State              %LOCALAPPDATA%\OSSteward (snapshots, preferences)
  OsSteward.Privacy            Redactor
  OsSteward.Core               ToolResult, Snapshot(+Comparer), Finding (platform-neutral)
```

More: [System Overview](docs/architecture/System-Overview.md) ·
[ADRs](docs/architecture/decisions/) ·
[MCP tool contract](docs/architecture/Mcp-Tools.md)

## Installation & quick start (development)

Requirements: Windows, [.NET 10 SDK](https://dotnet.microsoft.com/).

```powershell
git clone https://github.com/Besorez/os-steward-framework.git
cd os-steward-framework
powershell -File scripts/install-git-hooks.ps1   # enable the pre-commit privacy guard
dotnet build
dotnet test
```

## Claude Code integration

The repository is a Claude Code plugin (`.claude-plugin/plugin.json`)
bundling:

- **MCP** — the `os-steward` stdio server with eleven tools:
  `os_process_list` · `os_process_inspect` · `os_process_tree` ·
  `os_performance_snapshot` · `os_startup_list` · `os_service_list` ·
  `os_service_inspect` · `os_snapshot_create` · `os_baseline_compare` ·
  `os_config_get` · `os_config_set`
- **Skills** — `investigate-slowdown` (more are planned; skills are added
  incrementally, each with evidence rules and stop conditions)
- **Hooks** — the destructive-command safety guard
- **Agents** — none yet by design: specialized agents are added only when
  they earn their complexity (§13)

## Development status

**V0.1 — Read-Only Foundation.** The vertical slice works end-to-end and is
verified on a live machine (30 xUnit tests + 42 guard self-tests + live MCP
scenario run). Implemented vs planned is tracked honestly in
[docs/STATUS.md](docs/STATUS.md) — nothing is claimed that is not built.

## Roadmap (abridged)

Next capability groups (full list in [STATUS](docs/STATUS.md)): more
collectors (services, drivers, tasks, network, storage, events) · detectors
· multi-snapshot learned baselines · finding persistence + investigation
traces · safe export pipeline · Level-2 reversible actions behind the
ActionProposal flow · plugin packaging with a self-contained server binary.

## Contributing & security

See [CONTRIBUTING.md](CONTRIBUTING.md) (invariants are non-negotiable;
synthetic test data only) and [SECURITY.md](SECURITY.md) (private
vulnerability reporting; never post raw machine data publicly).

## License

Apache-2.0 — see [LICENSE](LICENSE).

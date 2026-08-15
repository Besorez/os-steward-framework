# Safety Model

> **Status: Current** (Action Proposal section: **Designed**, not
> implemented). Canonical document for safety rules. Invariants
> OSF-INV-001…006, 012 live in
> [Constitution.md](../architecture/Constitution.md).

## Structural guarantee (primary)

The MCP tool API contains **only Level 0 (read) and Level 1 (recommend)
support** capabilities. There is no generic `execute_command` tool, no
delete, no modify, no kill, no registry write. The only writes the server
can perform are to its own local runtime storage (snapshots, preferences) —
files, not system state. Unsafe behavior is impossible through the
framework API, independent of any prompt.

Current tool surface (all read-only except the two marked):

```text
os_process_list        os_process_inspect      os_process_tree
os_performance_snapshot                        os_startup_list
os_snapshot_create     (writes a local state file)
os_baseline_compare
os_config_get          os_config_set           (writes a local config file)
```

## Deterministic safety hook (defense-in-depth)

`hooks/safety-guard.ps1` is a Claude Code `PreToolUse` hook for shell tools
(`hooks/hooks.json` for the plugin; `.claude/settings.json` for this repo's
own development). It blocks (exit 2) commands matching destructive or
system-modifying patterns: file deletion (`Remove-Item`, `rm`, `del`,
`rmdir`, all `Remove-*` cmdlets), content destruction (`Clear-*`), registry
mutation (`reg add/delete`, `Set-ItemProperty`), service/task/process
mutation (`sc delete/stop`, `Stop-Service`, `Stop-Process`, `taskkill`,
`schtasks /create|/change|/delete`), disk destruction (`format`, `diskpart`,
`Format-Volume`), shutdown/restart, and dangerous Git commands (force push,
history rewrite, `git clean`, `git reset --hard`).

Properties:
- **Fail-closed**: unreadable or unparsable hook payload → block.
- **Prefers false positives**: an over-blocked benign command is acceptable;
  a passed destructive command is not. The owner can always run a genuinely
  needed command manually, outside the agent.
- **Tested**: embedded `-SelfTest` cases (blocked and allowed sets) run in
  CI-able form via `GuardScriptTests`.
- **Limits**: pattern matching cannot catch every obfuscation. This is
  acceptable because the hook is the second layer; the structural guarantee
  above is the first.

## Error honesty

`ToolResult` distinguishes `noData`, `permissionDenied`, `collectorFailed`,
`unsupported`, `notAvailable`, `invalidRequest`. Collectors report
per-field unavailability (`unavailableFields`) and warnings. "Access denied"
is never converted into "no anomaly found".

## Least privilege

No elevation is requested or required. Protected-process fields degrade
per-field with explicit markers. If a future capability needs elevation, it
must explain why, what becomes accessible, and the risk — then ask.

## Action Proposal model (Designed — NOT implemented)

Level 2 (reversible modification) does not exist in V0.1. When it is built,
every change must flow through an `ActionProposal`:

```text
ActionId, ActionType, Target, Reason, Evidence, ExpectedImpact,
Risk, Reversible (must be true), Rollback, Verification,
RequiresConfirmation, Status
Proposed → AwaitingConfirmation → Approved → Executed → Verified
Proposed → Rejected
```

There is no route from Finding directly to Execution. Level 3 (destructive)
will never exist.

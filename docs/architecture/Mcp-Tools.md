# MCP Tool Contract

> **Status: Current.** Canonical catalog of the OS Steward MCP tool surface.
> Server: `src/OsSteward.Mcp` (ModelContextProtocol SDK, stdio transport).
> Design rules: typed, narrow, predictable, auditable (§14); no generic
> execute-command tool exists (ADR-0003).

## Envelope

Every tool returns one text content item: a JSON `ToolResult`, redacted
centrally in `ToolEnvelope` before leaving the server:

```jsonc
{
  "success": true,
  "timestamp": "2026-08-16T13:00:28+00:00",
  "source": "os_process_inspect",        // tool name
  "data": { /* tool-specific */ },        // null on failure
  "warnings": ["disk:NotAvailable …"],   // partial-visibility notes
  "errors": [ { "kind": "permissionDenied", "message": "…" } ],
  "redactionState": "redacted"
}
```

`errors[].kind`: `noData` · `permissionDenied` · `collectorFailed` ·
`unsupported` · `notAvailable` · `invalidRequest`. A failed tool never
invents data; unreadable fields appear in `unavailableFields` as
`"field:Reason"`. Redaction guarantees no raw username, machine name, or
user-profile path in any response.

## Tools (Level 0/1 only)

| Tool | Args | Data | Writes |
|---|---|---|---|
| `os_process_list` | — | `{count, processes[]}`: pid, name, parentPid, executablePath, startTime, workingSetBytes, totalCpuSeconds, unavailableFields. No command lines/owners (OSF-INV-011). | no |
| `os_process_inspect` | `pid` | adds commandLine, owner, signature `{status: signed\|unsigned\|invalid\|unknown, signer}`, sha256, parentChain[], children[] | no |
| `os_process_tree` | `pid?` | `{roots[]}` nested `{pid, name, executablePath, children[]}`; subtree when pid given | no |
| `os_performance_snapshot` | `sampleMilliseconds?` (100–5000, default 500) | cpuTotalPercent, processorCount, memory `{totalBytes, availableBytes, usedPercent}`, disk `{percentDiskTime, avgQueueLength}` or null+warning, topCpu[], topMemory[], sampleMilliseconds | no |
| `os_startup_list` | — | `{count, entries[]}`: source registry\|folder, scope machine\|user, location, name, command | no |
| `os_service_list` | — | `{count, services[]}`: name, displayName, state, startMode, processId, pathName, account. No descriptions/signatures (OSF-INV-011). | no |
| `os_service_inspect` | `name` (short name) | adds description, resolved executablePath (quoted + unquoted-with-spaces command lines), signature, sha256 | no |
| `os_snapshot_create` | `category` (`processes`\|`startup`\|`services`) | `{snapshotId, category, itemCount, storageRoot}` | local state file |
| `os_baseline_compare` | `category`, `referenceSnapshotId?` | reference metadata + addedCount/removedCount/changedCount + added[]/removed[]/changed[]; identity keys and changed-field rules per category live in `CategoryComparers` (services: config changes only, state flips ignored) — see [Baseline-Model](../concepts/Baseline-Model.md) | no |
| `os_config_get` | — | `{language, allowedLanguages}` | no |
| `os_config_set` | `key` (`language`), `value` (`auto`\|`en`\|`uk`) | `{language}` | local config file |

The only writes in the entire surface are the two local files noted above —
never system state.

## Evolution rules

Adding a tool requires: read-only or ActionProposal-gated; narrowest
possible scope; `ToolResult` envelope through `ToolEnvelope`; explicit
failure semantics; an entry in this table; tests. Canonical dotted names
(`os.process.list`) map to underscore MCP names (`os_process_list`) —
the MCP tool-name charset excludes dots.

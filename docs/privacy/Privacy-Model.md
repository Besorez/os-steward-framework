# Privacy Model

> **Status: Current.** Canonical document for privacy rules. Constitution
> invariants OSF-INV-007…011 are defined in
> [Constitution.md](../architecture/Constitution.md); this document specifies
> how they are implemented.

## Runtime isolation

All machine state lives physically outside the repository:

```text
%LOCALAPPDATA%\OSSteward\
├── config\            preferences.json (language, …)
├── state\
│   ├── snapshots\     <category>\<id>.json
│   ├── baselines\     (reserved)
│   └── history\       (reserved)
├── findings\          (reserved)
├── reports\           (reserved)
└── logs\              (reserved)
```

Resolution order (implemented in `src/OsSteward.State/RuntimePaths.cs`):
explicit override (tests) → `OSSTEWARD_HOME` env var → `%LOCALAPPDATA%\OSSteward`.
Tests always point the root at a temp directory; they never touch real state.

The snapshot store is append-only: it can create and read snapshots but has
no delete capability (OSF-INV-001 applies to the framework's own state too).

## Redaction

`src/OsSteward.Privacy/Redactor.cs` rewrites machine identifiers in any text
leaving raw local storage:

| Raw | Redacted |
|---|---|
| `C:\Users\<current user>\…` | `%USERPROFILE%\…` |
| `C:\Users\<any other user>\…` | `C:\Users\<USER>\…` |
| current machine name | `<LOCAL_MACHINE>` |
| current username token | `<USER>` |

Patterns tolerate `\`, JSON-escaped `\\`, and `/` separators, so redaction
runs over serialized JSON. Every MCP response passes through the redactor in
one place (`ToolEnvelope`) — no tool can leak by forgetting a field. The
`redactionState` field in every `ToolResult` declares `rawLocal` or
`redacted`. Raw values stay in local snapshots only.

Synthetic identities exempt from redaction and guards (use these in fixtures
and docs): users `TestUser`, `ExampleUser`; machines `TESTBOX-01`,
`DESKTOP-TESTBOX`, `TESTMACHINE-99`.

## Git protection (defense-in-depth layers)

1. **Physical isolation** — machine state is never inside the repo (above).
2. **`.gitignore`** — local runtime dirs, capture formats (`.evtx`, `.etl`,
   `.pml`, `.dmp`), databases, secrets/keys, env files, IDE/Claude local
   state, build output.
3. **Pre-commit privacy guard** — `scripts/privacy-guard.ps1`, wired via
   `scripts/install-git-hooks.ps1` (`core.hooksPath .githooks`).
   Deterministic scan of staged content for: user-profile paths, the current
   username/machine name, default machine-name patterns, MachineGuid values,
   private keys, credential tokens, MAC addresses, forbidden file types.
   On a hit: **commit blocked** with file / category / match / suggestion.
   The guard never modifies files. Exceptions exist only via the reviewed
   `scripts/privacy-guard-allowlist.json` (path glob + explicit categories);
   there is deliberately no global skip flag (OSF-INV rule §62).
   The guard has an embedded self-test suite (`-SelfTest`), run by
   `tests/OsSteward.Platform.Windows.Tests/GuardScriptTests.cs`.

## Safe export (Planned)

Future shareable reports: Local finding → Redaction → Secret scan →
Machine-identifier scan → sanitized artifact. Sanitization never modifies
the raw local finding.

## Synthetic test data only

Repository fixtures (`tests/fixtures/`) are generated, fictional data —
never sanitized real dumps without deliberate review. Logging (when
implemented) stays local, supports levels, never intentionally logs secrets
or full environment-variable sets.

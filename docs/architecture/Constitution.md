# OS Steward Architecture Constitution

> **Status: Current.** This is the canonical document for project invariants.
> Other documents reference these rules; they do not redefine them.
> An invariant may only be changed by explicit project-owner decision, with
> consequences analyzed and tests updated (see Change Review below).

OS Steward is an AI-assisted operating-system stewardship framework. Claude
acts as investigator, reasoning layer, and orchestrator over narrow, typed
framework tools — never as an unrestricted shell operator.

## Invariants

### OSF-INV-001 — NO DELETE
OS Steward never deletes user or operating-system data. No deletion
capability exists in the tool API (no `delete_file`, `remove_registry_key`,
`delete_service`, recycle-bin clearing, formatting, etc.). The correct flow
is Detect → Explain → Recommend, never Detect → Delete.

### OSF-INV-002 — NO DESTRUCTIVE ACTIONS
No permanently destructive action is implemented as a capability. This is
enforced structurally (the capability does not exist), not by prompt
instructions alone.

### OSF-INV-003 — READ-ONLY BY DEFAULT
The default operating mode is read-only investigation (processes, services,
startup, tasks, performance, storage, events, network, signatures, hashes,
baselines, history). A diagnostic question is permission for relevant
read-only investigation; it is not interrupted by unnecessary confirmations.

### OSF-INV-004 — EXPLICIT CONFIRMATION BEFORE SYSTEM CHANGE
Any system-changing operation requires explicit user approval of that
specific proposed action: Investigation → Recommendation → Action Proposal →
Impact/Risk/Rollback explanation → approval → execute → verify. No approval
= no change. General past approval is not unlimited authorization.

### OSF-INV-005 — REVERSIBILITY BEFORE ACTION
A system-changing action may exist only if it is reversible and its rollback
procedure is known (before state, proposed change, expected result, risk,
rollback, verification). No definable rollback = do not execute.

### OSF-INV-006 — EVIDENCE BEFORE CONCLUSION
No conclusion from a process name, vendor, path, or intuition alone. Every
conclusion references evidence (ancestry, path, command line, signature,
hash, timestamps, history, baseline comparison, events…). If evidence is
insufficient, the answer is "Insufficient evidence" — certainty is never
fabricated.

### OSF-INV-007 — LOCAL-FIRST
Machine telemetry and runtime state stay local by default. No automatic
upload, sync, or publication of telemetry, snapshots, logs, or findings.

### OSF-INV-008 — NO MACHINE DATA IN GIT
The repository contains only reusable framework implementation and synthetic
examples. Never: real usernames, machine names, MachineGuid, MACs, personal
paths, process/software inventories, real logs/captures/snapshots/baselines/
findings/reports, credentials, keys, tokens, Claude/MCP runtime state.

### OSF-INV-009 — REPOSITORY IS STATELESS
Git stores HOW OS Steward works; local runtime stores WHAT it knows about
this machine. The two are never mixed.

### OSF-INV-010 — PRIVACY BY ARCHITECTURE
Machine state physically lives outside the repository:
`%LOCALAPPDATA%\OSSteward\` (override: `OSSTEWARD_HOME` env var, used by
tests). `.gitignore` is defense-in-depth, not the primary isolation.
See [Privacy-Model](../privacy/Privacy-Model.md).

### OSF-INV-011 — MINIMUM NECESSARY DATA
Tools retrieve only what an investigation needs; prefer progressive
narrowing (summary before enumeration, single-process inspect before dumps).
Example: `os_process_list` deliberately excludes command lines and owners;
`os_process_inspect` retrieves them for one pid.

### OSF-INV-012 — NO HIDDEN ACTIONS
Any system modification must be visible to the user. Silent changes of any
kind are forbidden.

### OSF-INV-013 — ENGLISH SOURCE OF TRUTH
The entire public repository is English: code, comments, docs, schemas,
identifiers, commit messages. Internal state identifiers (e.g.
`status: suspicious`, `severity: medium`) are always English.

### OSF-INV-014 — CONFIGURABLE USER LANGUAGE
Interaction language is independent of repository language. Modes: `auto`
(default), `en`, `uk`. Stored locally in
`%LOCALAPPDATA%\OSSteward\config\preferences.json` (tools: `os_config_get`,
`os_config_set`). The presentation layer localizes; internal schemas do not.

## Permission levels

| Level | Meaning | Status |
|---|---|---|
| 0 | Read-only observation | Implemented, allowed by default |
| 1 | Recommendations | Implemented, allowed by default |
| 2 | Reversible modification, explicit confirmation | Not implemented (designed; see [Safety-Model](../security/Safety-Model.md)) |
| 3 | Destructive modification | Does not exist and never will |

## Change review

Before modifying an invariant: identify it, explain why it is insufficient,
describe security/privacy consequences, provide alternatives, obtain explicit
owner approval, then update this document and affected tests. Invariants are
never weakened indirectly.

# ADR-0001 — Runtime Data Outside the Repository

**Status:** Accepted (2026-08-15) · **Owner invariants:** OSF-INV-008/009/010

## Context

OS Steward continuously learns machine-specific facts (snapshots, baselines,
findings, preferences). If any of it lived inside the working tree, one
careless `git add` away from publication, `.gitignore` would be the only
barrier — a single point of failure for user privacy.

## Decision

All runtime state lives physically outside the repository at
`%LOCALAPPDATA%\OSSteward\`, resolved by `RuntimePaths` (explicit override →
`OSSTEWARD_HOME` env var → default). The repository stores only framework
implementation and synthetic examples. `.gitignore` and the pre-commit
privacy guard remain as defense-in-depth, not as the primary isolation.

## Consequences

- Machine data cannot be committed by accident because it is never inside
  the repo tree.
- Tests must construct `RuntimePaths` with temp-dir overrides (they do).
- Uninstalling the repo does not remove learned state; a future
  user-initiated cleanup story is needed (framework itself will not delete).

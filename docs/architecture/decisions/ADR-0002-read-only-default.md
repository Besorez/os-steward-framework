# ADR-0002 — Read-Only Default

**Status:** Accepted (2026-08-15) · **Owner invariants:** OSF-INV-003/004/005

## Context

An AI agent with system-modification power amplifies its own mistakes: a
wrong hypothesis becomes a wrong action. Diagnostics, however, requires
broad reading without constant confirmation friction.

## Decision

Operating Level 0 (observe) and Level 1 (recommend) are the default and the
only implemented levels. A user's diagnostic question authorizes relevant
read-only investigation without further prompts. Level 2 (reversible
modification behind per-action explicit confirmation and a known rollback)
is designed but unimplemented; Level 3 (destructive) will never exist.

## Consequences

- V0.1 can be trusted with autonomy during investigation.
- Users must apply recommendations manually until Level 2 exists — the
  framework explains impact, risk, and undo steps instead of acting.
- Every future Level 2 capability must arrive with the ActionProposal
  lifecycle already enforced (see Safety-Model.md).

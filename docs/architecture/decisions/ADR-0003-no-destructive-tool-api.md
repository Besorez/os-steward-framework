# ADR-0003 — No Destructive Tool API (Structural Enforcement)

**Status:** Accepted (2026-08-15) · **Owner invariants:** OSF-INV-001/002

## Context

Prompt-level rules ("never delete") are advisory: they can be forgotten,
overridden, or jailbroken. If a destructive capability exists in the API,
some execution path eventually reaches it.

## Decision

Destructive and system-modifying capabilities are excluded from the MCP tool
API entirely — there is no delete, kill, registry-write, or generic
execute-command tool to call. The deterministic safety hook
(`hooks/safety-guard.ps1`) that blocks destructive shell commands is the
second layer, not the guarantee.

## Consequences

- Safety holds independently of model behavior or prompt quality.
- New tools must pass the mantra checklist (read-only? narrower possible?)
  in review; the API surface is the security boundary and grows carefully.
- The safety hook may over-block benign commands (accepted trade-off:
  false positives are recoverable, false negatives are not).

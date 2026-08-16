# ADR-0005 — Configurable Interaction Language

**Status:** Accepted (2026-08-15) · **Owner invariant:** OSF-INV-014

## Context

ADR-0004 fixes the repository to English, but the user talking to OS Steward
may prefer another language. Language preference is user state, so it must
not live in Git (OSF-INV-008).

## Decision

Interaction language modes `auto` (default), `en`, `uk`, stored locally in
`%LOCALAPPDATA%\OSSteward\config\preferences.json` via `os_config_get` /
`os_config_set`. `auto` means: respond in the language the user writes in.
Skills instruct the model to localize presentation while leaving tool data
and identifiers untouched. Enforcement is tested: enum identifiers remain
English under a `uk-UA` culture (`ToolResultTests`).

## Consequences

- Adding a language is a preference-list change plus skill guidance — no
  schema changes.
- `auto` quality depends on the model's detection; an explicit `en`/`uk`
  setting always wins.

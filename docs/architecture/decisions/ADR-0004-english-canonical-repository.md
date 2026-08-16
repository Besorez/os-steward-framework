# ADR-0004 — English Canonical Repository

**Status:** Accepted (2026-08-15) · **Owner invariant:** OSF-INV-013

## Context

The project owner communicates in Ukrainian; the project aims to be a
reusable open-source framework. Mixed-language sources fragment the
contributor base and produce schema identifiers that break tooling.

## Decision

Everything in the repository is English: code, comments, docs, schemas,
status identifiers, commit messages. Internal state values
(`severity: medium`, `status: suspicious`) are always English regardless of
who is reading.

## Consequences

- Any contributor can read the entire project; identifiers are stable for
  tests and integrations.
- User-facing localization is a presentation concern only (see ADR-0005).

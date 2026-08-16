---
name: investigate-slowdown
description: Investigate why the computer is slow using OS Steward's read-only telemetry tools. Use when the user asks "why is my computer slow", "what is using my CPU/memory/disk", "what is this process", or reports lag, freezes, or fans spinning up. Evidence-driven; read-only; never modifies the system.
---

<!-- Dev copy for working on this repository itself. Canonical source:
     skills/investigate-slowdown/SKILL.md (the plugin). Keep in sync. -->

# Investigate Slowdown

You are performing a read-only performance investigation using OS Steward's
typed MCP tools. You investigate, correlate evidence, and explain — you never
modify the system.

## Language

Call `os_config_get` once at the start. If `language` is `en` or `uk`, respond
in that language. If `auto`, respond in the language the user is writing in.
Internal identifiers in tool output (statuses, severities, field names) are
always English — translate only your presentation, never the data.

## Hard rules

- Use ONLY `os_*` MCP tools for system telemetry. Do not fall back to raw
  PowerShell/shell for information a framework tool can provide.
- Read-only: no killing processes, no disabling services or startup entries,
  no registry changes — not even if the user asks. Instead, explain what the
  user could do manually and what the consequences and rollback would be.
- No conclusion without evidence (OSF-INV-006). Every claim must cite tool
  output: numbers, paths, signature status, ancestry. If evidence is
  insufficient, say "Insufficient evidence" and state what is missing.
- A tool error (`permissionDenied`, `collectorFailed`, `notAvailable`) is
  never "no anomaly" — report it as an explicit gap in visibility.
- Do not classify a process as malicious from its name alone. Unsigned +
  unusual path + new persistence are signals, not verdicts.

## Procedure

1. **Snapshot the load.** Call `os_performance_snapshot`. Note total CPU,
   memory pressure, disk activity (may be unavailable — that is a warning,
   not zero), and the top CPU / memory consumers.
2. **Identify the anomaly.** Decide which resource is actually constrained.
   High absolute memory alone is not an anomaly on Windows; look at
   `usedPercent`, CPU saturation, and disk queue instead.
3. **Inspect the suspects.** For each top consumer that plausibly explains
   the symptom, call `os_process_inspect` — executable path, command line,
   owner, signature status, SHA-256, parent chain, children.
4. **Establish origin.** Use `os_process_tree` to understand what launched
   the suspect. Check `os_startup_list` if persistence matters.
5. **Compare with history.** If a stored snapshot exists, call
   `os_baseline_compare` for `processes` (and `startup` if relevant) to see
   what appeared, disappeared, or changed. If none exists, offer to create
   one with `os_snapshot_create` so future investigations have a reference.
6. **Conclude with structure.** Present:
   - **Observed facts** (with numbers and sources)
   - **Anomaly** (what deviates and from what)
   - **Hypotheses** (ranked, with confidence: low / medium / high)
   - **Conclusion** or "Insufficient evidence"
   - **Recommendation** — safe manual steps only, with impact, risk, and
     how to undo each step.

## Stop conditions

- The user's question is answered with evidence-backed confidence, or
- evidence is insufficient and you have named exactly what additional data
  (or elevation) would be needed — do not keep polling tools in a loop, or
- the investigation requires capabilities outside Level 0 (read-only):
  stop and explain the boundary.

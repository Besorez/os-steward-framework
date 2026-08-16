# Finding Model

> **Status: Designed** (schema implemented and tested in
> `src/OsSteward.Core/Findings/Finding.cs`; persistence and lifecycle
> tooling Planned). Real findings will live only in `<runtime>/findings/`.

A finding is a first-class investigation artifact:

```jsonc
{
  "findingId": "…",
  "type": "resource-anomaly",       // free-form, English, kebab-case
  "severity": "medium",             // info | low | medium | high | critical
  "confidence": "high",             // low | medium | high
  "subject": "pid 25224 example.exe",
  "observedAt": "2026-08-16T13:00:00+00:00",
  "summary": "…",
  "evidence": [ { "source": "os_performance_snapshot", "description": "…", "value": "…" } ],
  "hypotheses": [ { "description": "…", "confidence": "medium", "rejected": false, "rejectionReason": null } ],
  "conclusion": null,               // requires evidence; may stay null
  "recommendation": null,           // safe manual steps only in V0.x
  "status": "explained"
}
```

Lifecycle (`FindingStatus`):

```text
detected → investigating → evidenceCollected → explained
         → recommendationAvailable → resolved
detected → insufficientEvidence          (a valid terminal state)
```

Rules (OSF-INV-006):

- a `conclusion` must be supported by `evidence` entries — never by a name,
  vendor, or intuition alone;
- if evidence is insufficient, status is `insufficientEvidence` and the
  conclusion stays null; fabricated certainty is a defect;
- a security-flavored finding must separate observed fact / anomaly /
  hypothesis / confidence / conclusion (§24) — "anomaly detected" is not
  "virus detected";
- there is no path from a finding to execution: recommendations describe
  manual steps (V0.x) or, in the future, feed the ActionProposal flow
  ([Safety-Model](../security/Safety-Model.md)).

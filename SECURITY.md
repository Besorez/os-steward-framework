# Security Policy

## Scope

OS Steward is a **read-only diagnostics and reasoning framework**, not an
antivirus or EDR replacement. Its security posture rests on:

- no destructive or system-modifying capability in the tool API
  ([Safety Model](docs/security/Safety-Model.md));
- machine data isolated outside the repository and redacted before it
  reaches the model ([Privacy Model](docs/privacy/Privacy-Model.md));
- deterministic guards (safety hook, Git privacy guard) that fail closed.

## Reporting a vulnerability

If you find a way to make OS Steward delete/modify system state, bypass the
privacy guard or redaction, or exfiltrate machine data:

1. **Do not open a public issue with exploit details.**
2. Use GitHub's private vulnerability reporting on this repository
   (Security → Report a vulnerability), or contact the maintainer privately.
3. Include: affected component, reproduction steps, expected vs actual
   behavior, and impact. **Sanitize every path, hostname, and username in
   your report.**

You can expect an acknowledgement within a reasonable time; fixes for
guard/redaction bypasses are treated as the highest priority.

## What must never be posted publicly

Whether in issues, discussions, or pull requests:

- raw Windows Event Logs (`.evtx`), ETW traces (`.etl`), Procmon captures
  (`.pml`), crash dumps (`.dmp`);
- real OS Steward snapshots, baselines, findings, or reports from your
  machine;
- credentials, tokens, private keys;
- unredacted filesystem paths, machine names, usernames, MachineGuid, MAC
  or IP addresses.

Use the synthetic identities documented in the
[Privacy Model](docs/privacy/Privacy-Model.md) (`TestUser`, `TESTBOX-01`, …)
when constructing examples.

## Diagnostic data expectations

OS Steward stores everything it learns about your machine in
`%LOCALAPPDATA%\OSSteward\` and uploads nothing. If you believe any
framework path can move machine data into the repository or over the
network, report it as a vulnerability.

<!--
PRIVACY: no machine data in diffs — no real paths, usernames, machine names,
captures, snapshots, or credentials. Fixtures must be synthetic
(docs/privacy/Privacy-Model.md). The pre-commit privacy guard must be
enabled locally: powershell -File scripts/install-git-hooks.ps1
-->

## What & why

## Checklist

- [ ] `dotnet build` and `dotnet test` pass (0 warnings — TreatWarningsAsErrors)
- [ ] No invariant weakened (docs/architecture/Constitution.md); invariant
      changes have explicit owner approval
- [ ] New/changed tools: ToolResult envelope, ToolEnvelope redaction,
      explicit failure semantics, entry in docs/architecture/Mcp-Tools.md
- [ ] Safety/privacy-relevant change: guard/redaction tests updated
- [ ] Only synthetic data in tests/fixtures and docs
- [ ] docs/STATUS.md updated if a capability status changed

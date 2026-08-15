<#
.SYNOPSIS
    Enables the OS Steward Git hooks (privacy guard) for this repository.

.DESCRIPTION
    Points core.hooksPath at the tracked .githooks directory so the
    pre-commit privacy guard runs on every commit. Local-only Git
    configuration; nothing is committed and nothing outside this
    repository is changed.
#>
$ErrorActionPreference = 'Stop'

$repoRoot = git rev-parse --show-toplevel
if ($LASTEXITCODE -ne 0) {
    Write-Host 'Not inside a Git repository.'
    exit 1
}

git config core.hooksPath .githooks
if ($LASTEXITCODE -ne 0) {
    Write-Host 'Failed to set core.hooksPath.'
    exit 1
}

Write-Host 'OS Steward Git hooks enabled (core.hooksPath = .githooks).'
Write-Host 'The pre-commit privacy guard will now scan every commit.'
exit 0

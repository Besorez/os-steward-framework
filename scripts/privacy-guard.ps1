<#
.SYNOPSIS
    OS Steward Git privacy guard — deterministic staged-file scanner.

.DESCRIPTION
    Scans files staged for commit for likely private machine data:
    user-profile paths, the current username/machine name, machine
    identifiers, private keys, tokens, MAC addresses, and raw
    diagnostic capture files.

    If potential private data is found the commit is BLOCKED (exit 1)
    and a report is printed: file, category, reason, suggestion.
    The guard never modifies or removes files.

    Exceptions are only possible through the reviewed allowlist file
    scripts/privacy-guard-allowlist.json (path glob + explicit
    categories). There is no global skip flag by design.

    Canonical privacy rules: docs/privacy/Privacy-Model.md

.PARAMETER SelfTest
    Runs the embedded deterministic self-tests instead of scanning
    the Git index. Exit 0 = all tests pass.
#>
[CmdletBinding()]
param(
    [switch]$SelfTest
)

$ErrorActionPreference = 'Stop'

# Extensions that must never be committed regardless of content.
$script:ForbiddenExtensions = @(
    '.evtx', '.etl', '.pml', '.dmp', '.mdmp', '.hdmp',
    '.db', '.sqlite', '.sqlite3', '.pfx', '.p12', '.pem', '.key', '.snk'
)

# Synthetic identities that are allowed to appear in fixtures and docs.
# Keep in sync with docs/privacy/Privacy-Model.md.
$script:SyntheticUserNames = @('TestUser', 'ExampleUser', 'Public', 'Default', 'All Users', 'Default User')

function Get-PrivacyFindings {
    param(
        [string]$Text
    )
    $findings = @()

    $syntheticAlternation = ($script:SyntheticUserNames | ForEach-Object { [regex]::Escape($_) }) -join '|'

    # 1. User-profile paths that are not synthetic identities.
    $userPathPattern = "[A-Za-z]:\\+Users\\+(?!(?:$syntheticAlternation|<USER>|%USERNAME%|\`$)(?:\\|\b))([^\\/:*?""<>|\r\n]+)"
    foreach ($m in [regex]::Matches($Text, $userPathPattern)) {
        $findings += [pscustomobject]@{
            Category   = 'UserProfilePath'
            Match      = $m.Value
            Reason     = 'Real user-profile path. Machine paths must not enter Git.'
            Suggestion = 'Replace with %USERPROFILE%\ or a synthetic path like C:\Users\TestUser\.'
        }
    }

    # 2. Current username as a standalone token.
    $currentUser = $env:USERNAME
    if ($currentUser -and $currentUser.Length -ge 3 -and ($script:SyntheticUserNames -notcontains $currentUser)) {
        if ($Text -match "\b$([regex]::Escape($currentUser))\b") {
            $findings += [pscustomobject]@{
                Category   = 'CurrentUsername'
                Match      = $currentUser
                Reason     = 'The current Windows username appears in staged content.'
                Suggestion = 'Replace with <USER> or a synthetic name.'
            }
        }
    }

    # 3. Current machine name as a standalone token.
    $currentMachine = $env:COMPUTERNAME
    if ($currentMachine -and $currentMachine.Length -ge 4) {
        if ($Text -match "\b$([regex]::Escape($currentMachine))\b") {
            $findings += [pscustomobject]@{
                Category   = 'CurrentMachineName'
                Match      = $currentMachine
                Reason     = 'The current machine name appears in staged content.'
                Suggestion = 'Replace with <LOCAL_MACHINE> or a synthetic name like TESTBOX-01.'
            }
        }
    }

    # 4. Windows default machine-name patterns.
    foreach ($m in [regex]::Matches($Text, '\b(?:DESKTOP|LAPTOP)-[A-Z0-9]{5,10}\b')) {
        if ($m.Value -notmatch '^(?:DESKTOP|LAPTOP)-TEST') {
            $findings += [pscustomobject]@{
                Category   = 'MachineNamePattern'
                Match      = $m.Value
                Reason     = 'Looks like a real default Windows machine name.'
                Suggestion = 'Use a synthetic name such as DESKTOP-TESTBOX or TESTBOX-01.'
            }
        }
    }

    # 5. MachineGuid with an actual GUID value.
    foreach ($m in [regex]::Matches($Text, 'MachineGuid[''"\s:=]+[0-9a-fA-F]{8}-[0-9a-fA-F-]{27,}')) {
        $findings += [pscustomobject]@{
            Category   = 'MachineGuid'
            Match      = $m.Value
            Reason     = 'A concrete MachineGuid value identifies a specific machine.'
            Suggestion = 'Remove the value or replace with 00000000-0000-0000-0000-000000000000.'
        }
    }

    # 6. Private key material.
    foreach ($m in [regex]::Matches($Text, '-----BEGIN [A-Z ]*PRIVATE KEY-----')) {
        $findings += [pscustomobject]@{
            Category   = 'PrivateKey'
            Match      = $m.Value
            Reason     = 'Private key material must never be committed.'
            Suggestion = 'Remove the key and rotate it if it was real.'
        }
    }

    # 7. Credential / token patterns.
    $tokenPatterns = @(
        'AKIA[0-9A-Z]{16}',
        'ghp_[A-Za-z0-9]{36,}',
        'github_pat_[A-Za-z0-9_]{20,}',
        'xox[baprs]-[A-Za-z0-9-]{10,}',
        'sk-ant-[A-Za-z0-9_-]{20,}',
        'eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}'
    )
    foreach ($p in $tokenPatterns) {
        foreach ($m in [regex]::Matches($Text, $p)) {
            $findings += [pscustomobject]@{
                Category   = 'CredentialToken'
                Match      = ($m.Value.Substring(0, [Math]::Min(12, $m.Value.Length)) + '...')
                Reason     = 'Looks like an API key, token, or credential.'
                Suggestion = 'Remove the credential and rotate it if it was real.'
            }
        }
    }

    # 8. MAC addresses.
    foreach ($m in [regex]::Matches($Text, '\b(?:[0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}\b')) {
        if ($m.Value -notmatch '^(00[:-]00[:-]00|FF[:-]FF[:-]FF)') {
            $findings += [pscustomobject]@{
                Category   = 'MacAddress'
                Match      = $m.Value
                Reason     = 'Looks like a hardware MAC address.'
                Suggestion = 'Replace with 00:00:00:00:00:00 or remove.'
            }
        }
    }

    return $findings
}

function Get-Allowlist {
    $allowlistPath = Join-Path $PSScriptRoot 'privacy-guard-allowlist.json'
    if (Test-Path $allowlistPath) {
        return (Get-Content $allowlistPath -Raw | ConvertFrom-Json)
    }
    return @()
}

function Test-Allowlisted {
    param($Allowlist, [string]$FilePath, [string]$Category)
    foreach ($entry in $Allowlist) {
        if ($FilePath -like $entry.path -and ($entry.categories -contains $Category)) {
            return $true
        }
    }
    return $false
}

function Invoke-PrivacyScan {
    $stagedFiles = @(git diff --cached --name-only --diff-filter=ACM)
    if ($LASTEXITCODE -ne 0) {
        Write-Host 'PRIVACY GUARD ERROR: unable to read the Git index. Blocking commit (fail-closed).'
        return 2
    }
    if (-not $stagedFiles -or $stagedFiles.Count -eq 0) {
        Write-Host 'Privacy guard: no staged files to scan.'
        return 0
    }

    $allowlist = Get-Allowlist
    $blocked = @()

    foreach ($file in $stagedFiles) {
        if ([string]::IsNullOrWhiteSpace($file)) { continue }

        $ext = [System.IO.Path]::GetExtension($file).ToLowerInvariant()
        if ($script:ForbiddenExtensions -contains $ext) {
            if (-not (Test-Allowlisted $allowlist $file 'ForbiddenFileType')) {
                $blocked += [pscustomobject]@{
                    File       = $file
                    Category   = 'ForbiddenFileType'
                    Match      = $ext
                    Reason     = 'Raw capture / database / key file types must never be committed.'
                    Suggestion = 'Keep this file in local runtime storage outside the repository.'
                }
            }
            continue
        }

        $content = git show ":$file" 2>$null | Out-String
        if ([string]::IsNullOrEmpty($content)) { continue }
        if ($content.Contains([char]0)) { continue }  # binary; type gate above is the control

        foreach ($finding in (Get-PrivacyFindings -Text $content)) {
            if (-not (Test-Allowlisted $allowlist $file $finding.Category)) {
                $blocked += [pscustomobject]@{
                    File       = $file
                    Category   = $finding.Category
                    Match      = $finding.Match
                    Reason     = $finding.Reason
                    Suggestion = $finding.Suggestion
                }
            }
        }
    }

    if ($blocked.Count -gt 0) {
        Write-Host ''
        Write-Host '=================================================='
        Write-Host ' COMMIT BLOCKED — potential private machine data'
        Write-Host '=================================================='
        foreach ($b in $blocked) {
            Write-Host ''
            Write-Host "  File:       $($b.File)"
            Write-Host "  Category:   $($b.Category)"
            Write-Host "  Match:      $($b.Match)"
            Write-Host "  Reason:     $($b.Reason)"
            Write-Host "  Suggestion: $($b.Suggestion)"
        }
        Write-Host ''
        Write-Host 'No file was modified. Fix the content, or (for synthetic'
        Write-Host 'fixtures only) add a reviewed entry to scripts/privacy-guard-allowlist.json.'
        return 1
    }

    Write-Host "Privacy guard: scan passed ($($stagedFiles.Count) staged file(s))."
    return 0
}

function Invoke-SelfTest {
    $cases = @(
        @{ Name = 'blocks real user path';        Text = 'log at C:\Users\RealPerson\data.txt';                       Expect = 'UserProfilePath' }
        @{ Name = 'blocks json-escaped user path'; Text = '"path": "C:\\Users\\RealPerson\\x"';                        Expect = 'UserProfilePath' }
        @{ Name = 'allows TestUser path';          Text = 'C:\Users\TestUser\app.exe';                                 Expect = $null }
        @{ Name = 'allows ExampleUser path';       Text = 'C:\Users\ExampleUser\app.exe';                              Expect = $null }
        @{ Name = 'allows Public path';            Text = 'C:\Users\Public\shared.txt';                                Expect = $null }
        @{ Name = 'blocks machine-name pattern';   Text = 'host DESKTOP-QX7PL2M was here';                             Expect = 'MachineNamePattern' }
        @{ Name = 'allows synthetic machine';      Text = 'host DESKTOP-TESTBOX ok';                                   Expect = $null }
        @{ Name = 'blocks MachineGuid value';      Text = 'MachineGuid: 6f9619ff-8b86-d011-b42d-00c04fc964ff';         Expect = 'MachineGuid' }
        @{ Name = 'allows MachineGuid mention';    Text = 'never commit the MachineGuid registry value';               Expect = $null }
        @{ Name = 'blocks private key';            Text = '-----BEGIN RSA PRIVATE KEY-----';                           Expect = 'PrivateKey' }
        @{ Name = 'blocks AWS key';                Text = 'key=AKIAIOSFODNN7EXAMPLE';                                  Expect = 'CredentialToken' }
        @{ Name = 'blocks GitHub token';           Text = 'ghp_0123456789abcdef0123456789abcdef0123';                  Expect = 'CredentialToken' }
        @{ Name = 'blocks MAC address';            Text = 'adapter 3C-7A-8A-12-34-56 up';                              Expect = 'MacAddress' }
        @{ Name = 'allows plain text';             Text = 'A normal documentation sentence about processes.';          Expect = $null }
    )

    $failures = 0
    foreach ($case in $cases) {
        $findings = @(Get-PrivacyFindings -Text $case.Text)
        $categories = @($findings | ForEach-Object { $_.Category })
        $ok = if ($null -eq $case.Expect) { $categories.Count -eq 0 } else { $categories -contains $case.Expect }
        if ($ok) {
            Write-Host "  PASS  $($case.Name)"
        } else {
            Write-Host "  FAIL  $($case.Name) (expected: $($case.Expect); got: $($categories -join ', '))"
            $failures++
        }
    }

    if ($failures -gt 0) {
        Write-Host "Privacy guard self-test: $failures failure(s)."
        return 1
    }
    Write-Host 'Privacy guard self-test: all cases passed.'
    return 0
}

if ($SelfTest) {
    exit (Invoke-SelfTest)
}
exit (Invoke-PrivacyScan)

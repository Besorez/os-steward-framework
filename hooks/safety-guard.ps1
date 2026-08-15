<#
.SYNOPSIS
    OS Steward safety guard — deterministic destructive-command blocker.

.DESCRIPTION
    Claude Code PreToolUse hook for shell tools (Bash / PowerShell).
    Reads the hook JSON payload from stdin, extracts the proposed
    command, and blocks it (exit 2) if it matches a known destructive
    or system-modifying pattern.

    Fail-closed: if the payload cannot be parsed or the command cannot
    be determined, the operation is blocked with an explanation.

    This hook is defense-in-depth. The primary guarantee is structural:
    the OS Steward MCP tool API contains no destructive capability at all.
    Canonical safety rules: docs/security/Safety-Model.md

.PARAMETER SelfTest
    Runs the embedded deterministic self-tests instead of reading stdin.
    Exit 0 = all tests pass.
#>
[CmdletBinding()]
param(
    [switch]$SelfTest
)

$ErrorActionPreference = 'Stop'

# Each rule: Category, Pattern (case-insensitive regex), Reason.
$script:Rules = @(
    @{ Category = 'FileDeletion'
       Pattern  = '(^|[;|&\s(={])(Remove-Item|rm|ri|rmdir|rd|del|erase)(\.exe)?(\s|$)'
       Reason   = 'File or directory deletion is forbidden (OSF-INV-001 NO DELETE).' }
    @{ Category = 'FileDeletion'
       Pattern  = '(^|[;|&\s(={])Remove-[A-Za-z]+'
       Reason   = 'Remove-* cmdlets delete system or user state (OSF-INV-001 NO DELETE).' }
    @{ Category = 'ContentDestruction'
       Pattern  = 'Clear-(Content|RecycleBin|EventLog|Disk|Tpm)'
       Reason   = 'Clearing content, recycle bin, event logs, or disks is destructive.' }
    @{ Category = 'RegistryModification'
       Pattern  = 'reg(\.exe)?\s+(delete|add|import|restore)|Set-ItemProperty|New-ItemProperty|Rename-ItemProperty'
       Reason   = 'Registry modification requires the (future) action-proposal flow with explicit approval.' }
    @{ Category = 'ServiceModification'
       Pattern  = 'sc(\.exe)?\s+(delete|stop|config|failure)|Stop-Service|Set-Service|New-Service|Suspend-Service|Restart-Service'
       Reason   = 'Service modification is a system change; OS Steward V0.1 is read-only.' }
    @{ Category = 'ProcessTermination'
       Pattern  = 'Stop-Process|taskkill(\.exe)?|\bkill\s+-'
       Reason   = 'Terminating processes is a system change; OS Steward V0.1 is read-only.' }
    @{ Category = 'DiskDestruction'
       Pattern  = '\bformat(\.com)?\s+[A-Za-z]:|diskpart|Format-Volume|Initialize-Disk|New-Partition|Remove-Partition|\bcipher(\.exe)?\s+/w'
       Reason   = 'Disk formatting or partitioning is permanently destructive.' }
    @{ Category = 'ScheduledTaskModification'
       Pattern  = 'schtasks(\.exe)?\s+/(delete|change|create)|Unregister-ScheduledTask|Disable-ScheduledTask|Register-ScheduledTask'
       Reason   = 'Scheduled-task modification is a system change; OS Steward V0.1 is read-only.' }
    @{ Category = 'WmiDeletion'
       Pattern  = 'wmic\s+.*\bdelete\b'
       Reason   = 'WMI object deletion is destructive.' }
    @{ Category = 'SystemPower'
       Pattern  = 'shutdown(\.exe)?\s|Restart-Computer|Stop-Computer'
       Reason   = 'Restart/shutdown requires explicit user action, not agent action.' }
    @{ Category = 'GitHistoryDanger'
       Pattern  = 'git\s+push\s+[^\r\n]*(--force|-f\b)|git\s+[^\r\n]*filter-branch|git\s+clean\b|git\s+reset\s+--hard|git\s+checkout\s+--\s'
       Reason   = 'Force pushes, history rewrites, and work-discarding Git commands are forbidden without explicit owner action.' }
)

function Test-DestructiveCommand {
    param([string]$Command)
    foreach ($rule in $script:Rules) {
        if ($Command -match "(?i)$($rule.Pattern)") {
            return [pscustomobject]@{
                Category = $rule.Category
                Reason   = $rule.Reason
            }
        }
    }
    return $null
}

function Write-GuardError {
    param([string]$Message)
    # Write-Error is unusable here: with ErrorActionPreference=Stop it throws
    # and the process exits with code 1, but Claude Code only blocks on exit 2.
    [Console]::Error.WriteLine($Message)
}

function Invoke-Guard {
    $payloadText = ''
    try {
        $payloadText = [Console]::In.ReadToEnd()
    } catch {
        Write-GuardError 'OS Steward safety guard: could not read hook payload. Blocking (fail-closed).'
        return 2
    }

    $command = $null
    try {
        $payload = $payloadText | ConvertFrom-Json
        if ($payload.tool_input -and $payload.tool_input.command) {
            $command = [string]$payload.tool_input.command
        }
    } catch {
        Write-GuardError 'OS Steward safety guard: could not parse hook payload as JSON. Blocking (fail-closed).'
        return 2
    }

    if ([string]::IsNullOrWhiteSpace($command)) {
        Write-GuardError 'OS Steward safety guard: no command found in hook payload. Blocking (fail-closed).'
        return 2
    }

    $violation = Test-DestructiveCommand -Command $command
    if ($violation) {
        Write-GuardError ("OS Steward safety guard BLOCKED this command. " +
            "Category: $($violation.Category). $($violation.Reason) " +
            'If the project owner genuinely needs this operation, they must run it manually themselves.')
        return 2
    }

    return 0
}

function Invoke-SelfTest {
    $cases = @(
        @{ Name = 'blocks Remove-Item';        Command = 'Remove-Item C:\temp\x.txt';                       Blocked = $true }
        @{ Name = 'blocks rm -rf';             Command = 'rm -rf ./build';                                  Blocked = $true }
        @{ Name = 'blocks del';                Command = 'del important.docx';                              Blocked = $true }
        @{ Name = 'blocks rmdir';              Command = 'rmdir /s /q C:\data';                             Blocked = $true }
        @{ Name = 'blocks chained rm';         Command = 'echo ok; rm file.txt';                            Blocked = $true }
        @{ Name = 'blocks reg delete';         Command = 'reg delete HKLM\Software\X /f';                   Blocked = $true }
        @{ Name = 'blocks reg add';            Command = 'reg add HKCU\Software\X /v A /d 1';               Blocked = $true }
        @{ Name = 'blocks sc delete';          Command = 'sc delete Spooler';                               Blocked = $true }
        @{ Name = 'blocks Stop-Service';       Command = 'Stop-Service -Name wuauserv';                     Blocked = $true }
        @{ Name = 'blocks Stop-Process';       Command = 'Stop-Process -Id 4242';                           Blocked = $true }
        @{ Name = 'blocks taskkill';           Command = 'taskkill /PID 4242 /F';                           Blocked = $true }
        @{ Name = 'blocks format';             Command = 'format D: /q';                                    Blocked = $true }
        @{ Name = 'blocks diskpart';           Command = 'diskpart /s script.txt';                          Blocked = $true }
        @{ Name = 'blocks Clear-RecycleBin';   Command = 'Clear-RecycleBin -Force';                         Blocked = $true }
        @{ Name = 'blocks schtasks delete';    Command = 'schtasks /delete /tn BadTask /f';                 Blocked = $true }
        @{ Name = 'blocks shutdown';           Command = 'shutdown /r /t 0';                                Blocked = $true }
        @{ Name = 'blocks force push';         Command = 'git push origin main --force';                    Blocked = $true }
        @{ Name = 'blocks git clean';          Command = 'git clean -fd';                                   Blocked = $true }
        @{ Name = 'blocks git reset hard';     Command = 'git reset --hard origin/main';                    Blocked = $true }
        @{ Name = 'allows Get-Process';        Command = 'Get-Process | Select-Object -First 5';            Blocked = $false }
        @{ Name = 'allows git status';         Command = 'git status --short';                              Blocked = $false }
        @{ Name = 'allows git commit';         Command = 'git commit -m "docs: update"';                    Blocked = $false }
        @{ Name = 'allows dotnet test';        Command = 'dotnet test --nologo';                            Blocked = $false }
        @{ Name = 'allows reg query';          Command = 'reg query HKLM\Software\Microsoft';               Blocked = $false }
        @{ Name = 'allows dir listing';        Command = 'Get-ChildItem C:\ -Force';                        Blocked = $false }
        @{ Name = 'allows grep';               Command = 'grep -r "pattern" src/';                          Blocked = $false }
        @{ Name = 'allows sc query';           Command = 'sc query Spooler';                                Blocked = $false }
        @{ Name = 'allows schtasks query';     Command = 'schtasks /query /fo LIST';                        Blocked = $false }
    )

    $failures = 0
    foreach ($case in $cases) {
        $violation = Test-DestructiveCommand -Command $case.Command
        $wasBlocked = ($null -ne $violation)
        if ($wasBlocked -eq $case.Blocked) {
            Write-Host "  PASS  $($case.Name)"
        } else {
            $detail = if ($violation) { $violation.Category } else { 'not blocked' }
            Write-Host "  FAIL  $($case.Name) (result: $detail)"
            $failures++
        }
    }

    if ($failures -gt 0) {
        Write-Host "Safety guard self-test: $failures failure(s)."
        return 1
    }
    Write-Host 'Safety guard self-test: all cases passed.'
    return 0
}

if ($SelfTest) {
    exit (Invoke-SelfTest)
}
exit (Invoke-Guard)

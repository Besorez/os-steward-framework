<#
.SYNOPSIS
    On the PEER machine (admin): copy the watchdog and suspend scripts to ProgramData and register the
    watchdog to run every 5 minutes as SYSTEM.
.DESCRIPTION
    Rollback: Unregister-ScheduledTask 'Sleep Watchdog'; remove %ProgramData%\OSSteward-playbooks.
    Opt-out at any time: create the file %ProgramData%\OSSteward-playbooks\keep-awake.
.EXAMPLE
    .\Install-SleepWatchdogTask.ps1 -PeerHosts 192.0.2.167, WORKSTATION-A
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string[]]$PeerHosts,
    [int]$GraceMinutes = 10,
    [string]$TaskName = 'Sleep Watchdog'
)
$ErrorActionPreference = 'Stop'
$dir = "$env:ProgramData\OSSteward-playbooks"
New-Item -ItemType Directory -Force $dir | Out-Null
Copy-Item (Join-Path $PSScriptRoot 'Sleep-Watchdog.ps1') $dir -Force
Copy-Item (Join-Path $PSScriptRoot 'Suspend-Computer.ps1') $dir -Force

$ps = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$hosts = ($PeerHosts | ForEach-Object { "'$_'" }) -join ','
$action    = New-ScheduledTaskAction -Execute $ps -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$dir\Sleep-Watchdog.ps1`" -PeerHosts $hosts -GraceMinutes $GraceMinutes"
$trigger   = New-ScheduledTaskTrigger -Once -At (Get-Date).Date -RepetitionInterval (New-TimeSpan -Minutes 5)
$settings  = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 2) -MultipleInstances IgnoreNew -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -RunLevel Highest
Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description 'Sleep when the peer machine is absent and nobody is using this one' -Force | Out-Null
Get-ScheduledTask -TaskName $TaskName | Select-Object TaskName, State
Write-Output "scripts in $dir; opt-out sentinel: $dir\keep-awake"

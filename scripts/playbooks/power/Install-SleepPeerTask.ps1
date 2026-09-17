<#
.SYNOPSIS
    Register the "Peer Sleep" scheduled task on the PRIMARY machine: when this machine enters sleep
    (System log event Microsoft-Windows-Kernel-Power / 42), ask the peer to sleep over SSH.
.DESCRIPTION
    Best-effort fast path; pair it with the watchdog on the peer (Install-SleepWatchdogTask.ps1).
    Rollback: Unregister-ScheduledTask 'Peer Sleep'.
.EXAMPLE
    .\Install-SleepPeerTask.ps1 -SshHost peer
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$SshHost,
    [string]$RemoteScript = 'C:\ProgramData\OSSteward-playbooks\Suspend-Computer.ps1',
    [string]$TaskName = 'Peer Sleep'
)
$ErrorActionPreference = 'Stop'
$ps = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$script = Join-Path $PSScriptRoot 'Sleep-Peer.ps1'
$entering = New-CimInstance -CimClass (Get-CimClass MSFT_TaskEventTrigger root/Microsoft/Windows/TaskScheduler) -ClientOnly
$entering.Enabled = $true
$entering.Subscription = "<QueryList><Query Id='0' Path='System'><Select Path='System'>*[System[Provider[@Name='Microsoft-Windows-Kernel-Power'] and EventID=42]]</Select></Query></QueryList>"
$action   = New-ScheduledTaskAction -Execute $ps -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$script`" -SshHost $SshHost -RemoteScript `"$RemoteScript`""
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 1) -MultipleInstances IgnoreNew
Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $entering -Settings $settings -Description 'Ask the peer machine to sleep when this machine enters sleep' -Force | Out-Null
Get-ScheduledTask -TaskName $TaskName | Select-Object TaskName, State

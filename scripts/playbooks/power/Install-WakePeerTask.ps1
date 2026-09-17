<#
.SYNOPSIS
    Register the "Peer Wake" scheduled task on the PRIMARY machine: send Wake-on-LAN at logon and on resume.
.DESCRIPTION
    Runs as the current user (no admin needed). Triggers: at logon of this user; System log event
    Microsoft-Windows-Power-Troubleshooter / 1 (resumed from sleep). Rollback: Unregister-ScheduledTask 'Peer Wake'.
.EXAMPLE
    .\Install-WakePeerTask.ps1 -Mac '<peer MAC>' -Broadcast 192.0.2.255 -PeerHost 192.0.2.51
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Mac,
    [Parameter(Mandatory)][string]$Broadcast,
    [Parameter(Mandatory)][string]$PeerHost,
    [string]$TaskName = 'Peer Wake'
)
$ErrorActionPreference = 'Stop'
$ps = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$script = Join-Path $PSScriptRoot 'Wake-Peer.ps1'
$resume = New-CimInstance -CimClass (Get-CimClass MSFT_TaskEventTrigger root/Microsoft/Windows/TaskScheduler) -ClientOnly
$resume.Enabled = $true
$resume.Subscription = "<QueryList><Query Id='0' Path='System'><Select Path='System'>*[System[Provider[@Name='Microsoft-Windows-Power-Troubleshooter'] and EventID=1]]</Select></Query></QueryList>"
$action   = New-ScheduledTaskAction -Execute $ps -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$script`" -Mac $Mac -Broadcast $Broadcast -PeerHost $PeerHost"
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 3) -MultipleInstances IgnoreNew
Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger @((New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME), $resume) -Settings $settings -Description 'Wake the peer machine via WoL at logon and on resume' -Force | Out-Null
Get-ScheduledTask -TaskName $TaskName | Select-Object TaskName, State

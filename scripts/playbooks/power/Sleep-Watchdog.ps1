<#
.SYNOPSIS
    Sleep this machine when the peer has been absent for a grace period and nobody is using it.
.DESCRIPTION
    Meant to run every 5 minutes as SYSTEM (see Install-SleepWatchdogTask.ps1). Guards:
      - skip for 5 minutes after boot or resume;
      - skip while the sentinel file exists (opt-out for days the machine must stay up alone);
      - skip while any session is Active (local console or a connected RDP session);
      - sleep only after the peer has failed ping for -GraceMinutes.
.PARAMETER PeerHosts
    Addresses/names to ping; any answer counts as "peer present".
.EXAMPLE
    .\Sleep-Watchdog.ps1 -PeerHosts 192.0.2.167, WORKSTATION-A -GraceMinutes 10
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string[]]$PeerHosts,
    [int]$GraceMinutes = 10,
    [string]$StateDir = "$env:ProgramData\OSSteward-playbooks",
    [string]$Sentinel = "$env:ProgramData\OSSteward-playbooks\keep-awake"
)
$ErrorActionPreference = 'SilentlyContinue'
New-Item -ItemType Directory -Force $StateDir | Out-Null
$state = Join-Path $StateDir 'watchdog-lastseen.txt'
$log   = Join-Path $StateDir 'power.log'
function Log($m) { "$(Get-Date -f 'yyyy-MM-dd HH:mm:ss') watchdog: $m" | Add-Content $log }

if (Test-Path $Sentinel) { exit 0 }

$up = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$lastWake = Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'Microsoft-Windows-Power-Troubleshooter'; Id = 1 } -MaxEvents 1
if ($up.TotalMinutes -lt 5 -or ($lastWake -and ((Get-Date) - $lastWake.TimeCreated).TotalMinutes -lt 5)) { exit 0 }

$ping = New-Object System.Net.NetworkInformation.Ping
foreach ($h in $PeerHosts) { try { if ($ping.Send($h, 1000).Status -eq 'Success') { (Get-Date).ToString('o') | Set-Content $state; exit 0 } } catch {} }

if (-not (Test-Path $state)) { (Get-Date).ToString('o') | Set-Content $state; exit 0 }
$idle = ((Get-Date) - [datetime](Get-Content $state)).TotalMinutes
if ($idle -lt $GraceMinutes) { exit 0 }

$active = qwinsta 2>$null | Select-String '\sActive\s' | Where-Object { $_ -notmatch '^\s*services' }
if ($active) { Log "peer absent $([int]$idle) min but active session present"; exit 0 }

Log "peer absent $([int]$idle) min, no active session -> sleep"
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::SetSuspendState([System.Windows.Forms.PowerState]::Suspend, $false, $false) | Out-Null

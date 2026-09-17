<#
.SYNOPSIS
    Task wrapper: wake the peer with Send-WakeOnLan.ps1 and log the outcome.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Mac,
    [Parameter(Mandatory)][string]$Broadcast,
    [Parameter(Mandatory)][string]$PeerHost,
    [string]$Log = "$env:LOCALAPPDATA\OSSteward-playbooks\power-link.log"
)
New-Item -ItemType Directory -Force (Split-Path $Log) | Out-Null
$out = & (Join-Path $PSScriptRoot '..\network\Send-WakeOnLan.ps1') -Mac $Mac -Broadcast $Broadcast -WaitForHost $PeerHost 2>&1
"$(Get-Date -f 'yyyy-MM-dd HH:mm:ss') wake: $($out -join ' | ')" | Add-Content $Log

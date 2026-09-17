<#
.SYNOPSIS
    Ask the peer machine to sleep, over SSH, using the Suspend-Computer.ps1 copy that lives on the peer.
.DESCRIPTION
    Fast path for the "this machine is entering sleep" event: 3-second connect timeout, result logged.
    ssh exit 255 after the call means the peer went down mid-session, i.e. success.
.PARAMETER SshHost
    Host alias from ~/.ssh/config (key-based, BatchMode).
.PARAMETER RemoteScript
    Path of Suspend-Computer.ps1 on the peer.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$SshHost,
    [string]$RemoteScript = 'C:\ProgramData\OSSteward-playbooks\Suspend-Computer.ps1',
    [string]$Log = "$env:LOCALAPPDATA\OSSteward-playbooks\power-link.log"
)
New-Item -ItemType Directory -Force (Split-Path $Log) | Out-Null
$out = & ssh -o BatchMode=yes -o ConnectTimeout=3 -o ServerAliveInterval=2 $SshHost "powershell -NoProfile -ExecutionPolicy Bypass -File $RemoteScript" 2>&1
"$(Get-Date -f 'yyyy-MM-dd HH:mm:ss') sleep sent to $SshHost, ssh exit $LASTEXITCODE, $($out -join ' ')" | Add-Content $Log

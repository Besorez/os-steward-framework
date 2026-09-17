<#
.SYNOPSIS
    Enter S3 sleep now, even when hibernation / Fast Startup is enabled (rundll32 SetSuspendState would hibernate).
.DESCRIPTION
    Intended to be launched by a peer machine over SSH: keep it in a file, never inline (quoting of $false
    breaks across shells). The SSH client sees exit 255 when the host goes down - that is success.
#>
[CmdletBinding()]
param([string]$Log = "$env:ProgramData\OSSteward-playbooks\power.log")
New-Item -ItemType Directory -Force (Split-Path $Log) | Out-Null
"$(Get-Date -f 'yyyy-MM-dd HH:mm:ss') suspend requested" | Add-Content $Log
Add-Type -AssemblyName System.Windows.Forms
$ok = [System.Windows.Forms.Application]::SetSuspendState([System.Windows.Forms.PowerState]::Suspend, $false, $false)
"SetSuspendState returned $ok"

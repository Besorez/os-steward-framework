<#
.SYNOPSIS
    Arm the wired adapter for Wake-on-LAN (magic packet) and report what can wake the machine.
.DESCRIPTION
    Run as administrator on the machine to be woken. Changing adapter power management resets the NIC:
    an SSH session that runs this script is dropped (exit 255) - reconnect and verify with
    powercfg /devicequery wake_armed. Rollback: Set-NetAdapterPowerManagement -WakeOnMagicPacket Disabled.
#>
[CmdletBinding()]
param([string]$AdapterName)
$ErrorActionPreference = 'SilentlyContinue'
$nic = if ($AdapterName) { Get-NetAdapter -Name $AdapterName } else { Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' -and $_.PhysicalMediaType -notmatch '802.11' } | Select-Object -First 1 }
if (-not $nic) { Write-Output 'no wired adapter found'; exit 1 }
'wake-armed before:'; powercfg /devicequery wake_armed
powercfg /deviceenablewake "$($nic.InterfaceDescription)" | Out-Null
Set-NetAdapterPowerManagement -Name $nic.Name -WakeOnMagicPacket Enabled -DeviceSleepOnDisconnect Disabled
'wake-armed after:'; powercfg /devicequery wake_armed
Get-NetAdapterPowerManagement -Name $nic.Name | Select-Object Name, WakeOnMagicPacket, DeviceSleepOnDisconnect | Format-Table -AutoSize

<#
.SYNOPSIS
    Let only a magic packet wake the machine: disable NIC pattern-match wake and other stray wake sources.
.DESCRIPTION
    Run as administrator on the peer. With "Wake on Pattern Match" enabled, ordinary LAN traffic
    (an SMB connection attempt, ARP/NS not covered by offload, some broadcasts) wakes the machine,
    which then idles back to sleep - dozens of cycles a day. This script:
      - disables pattern wake at the OS level and in the driver (*WakeOnPattern = 0),
      - keeps magic-packet wake enabled,
      - turns Energy Efficient Ethernet off (-DisableEee, default on),
      - removes wake permission from every other wake-armed device except keyboards and mice (-KeepOthers to skip).
    The adapter resets: an SSH session running this is dropped; reconnect after ~10 s and check with
    powercfg /devicequery wake_armed. Rollback: Set-NetAdapterPowerManagement -WakeOnPattern Enabled;
    powercfg /deviceenablewake "<device>".
#>
[CmdletBinding()]
param([string]$AdapterName, [bool]$DisableEee = $true, [switch]$KeepOthers)
$nic = if ($AdapterName) { Get-NetAdapter -Name $AdapterName } else { Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' -and $_.PhysicalMediaType -notmatch '802.11' } | Select-Object -First 1 }
if (-not $nic) { Write-Output 'no wired adapter found'; exit 1 }
'wake-armed before:'; powercfg /devicequery wake_armed
if (-not $KeepOthers) {
    powercfg /devicequery wake_armed | Where-Object { $_ -and $_ -ne $nic.InterfaceDescription -and $_ -notmatch 'keyboard|mouse|HID|NONE' } |
        ForEach-Object { "disable wake: $_"; powercfg /devicedisablewake "$_" }
}
Set-NetAdapterAdvancedProperty -Name $nic.Name -RegistryKeyword '*WakeOnPattern' -RegistryValue 0 -NoRestart -ErrorAction SilentlyContinue
if ($DisableEee) { Set-NetAdapterAdvancedProperty -Name $nic.Name -RegistryKeyword 'EEELinkAdvertisement' -RegistryValue 0 -NoRestart -ErrorAction SilentlyContinue }
# last: this one resets the adapter
Set-NetAdapterPowerManagement -Name $nic.Name -WakeOnMagicPacket Enabled -WakeOnPattern Disabled
Get-NetAdapterPowerManagement -Name $nic.Name | Select-Object Name, WakeOnMagicPacket, WakeOnPattern | Format-Table -AutoSize

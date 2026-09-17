<#
.SYNOPSIS
    Enable the Remote Desktop host (Pro/Enterprise only; Home editions have none) and its firewall group.
.NOTES
    Run as administrator. Rollback: fDenyTSConnections = 1 and Disable-NetFirewallRule -Group '@FirewallAPI.dll,-28752'.
#>
[CmdletBinding()]
param()
$edition = (Get-CimInstance Win32_OperatingSystem).Caption
if ($edition -match 'Home') { Write-Output "no RDP host on this edition ($edition); use SSH + SMB"; return }
Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 0
Enable-NetFirewallRule -Group '@FirewallAPI.dll,-28752'
$nla = (Get-CimInstance -Namespace root/cimv2/TerminalServices -ClassName Win32_TSGeneralSetting -Filter "TerminalName='RDP-Tcp'").UserAuthenticationRequired
Write-Output "RDP enabled on $edition; NLA=$nla; port 3389"

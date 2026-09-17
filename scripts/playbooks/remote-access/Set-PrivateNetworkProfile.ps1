<#
.SYNOPSIS
    Switch every connected network to the Private profile so the firewall allows LAN services.
.NOTES
    Run as administrator on the target machine. Rollback: Set-NetConnectionProfile -NetworkCategory Public.
#>
[CmdletBinding()]
param()
Get-NetConnectionProfile | Where-Object NetworkCategory -ne 'Private' | ForEach-Object {
    Set-NetConnectionProfile -InterfaceIndex $_.InterfaceIndex -NetworkCategory Private
    Write-Output "Private: $($_.InterfaceAlias)"
}
Get-NetConnectionProfile | Select-Object InterfaceAlias, NetworkCategory | Format-Table -AutoSize

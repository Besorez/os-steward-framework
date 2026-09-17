<#
.SYNOPSIS
    Enable the built-in firewall rule groups for LAN administration by language-independent ID.
.DESCRIPTION
    -DisplayGroup names are localized and fail on non-English Windows; the @FirewallAPI.dll resource
    IDs are stable across languages.
.PARAMETER Groups
    Any of: FileSharing, NetworkDiscovery, RemoteDesktop. Default: all three.
.NOTES
    Run as administrator. Rollback: Disable-NetFirewallRule -Group '<same id>'.
#>
[CmdletBinding()]
param([ValidateSet('FileSharing', 'NetworkDiscovery', 'RemoteDesktop')][string[]]$Groups = @('FileSharing', 'NetworkDiscovery', 'RemoteDesktop'))
$ids = @{
    FileSharing      = '@FirewallAPI.dll,-28502'
    NetworkDiscovery = '@FirewallAPI.dll,-32752'
    RemoteDesktop    = '@FirewallAPI.dll,-28752'
}
foreach ($g in $Groups) {
    Enable-NetFirewallRule -Group $ids[$g]
    $n = (Get-NetFirewallRule -Group $ids[$g] | Where-Object Enabled -eq True | Measure-Object).Count
    Write-Output "$g ($($ids[$g])): $n rules enabled"
}

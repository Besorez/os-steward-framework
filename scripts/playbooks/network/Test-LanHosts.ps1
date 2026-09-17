<#
.SYNOPSIS
    Read-only LAN sweep: which hosts answer ping, and which of them expose SSH / SMB / RDP.
.DESCRIPTION
    Pings every address of a /24 in parallel, then probes the given TCP ports on the hosts that
    answered (or on every address when -ProbeAll is set, for hosts that block ICMP). Resolves
    names via DNS. Changes nothing.
.PARAMETER Subnet
    First three octets, e.g. '192.0.2'.
.PARAMETER Ports
    TCP ports to probe. Default: 22 (SSH), 445 (SMB), 3389 (RDP).
.EXAMPLE
    .\Test-LanHosts.ps1 -Subnet 192.0.2
.EXAMPLE
    .\Test-LanHosts.ps1 -Subnet 192.0.2 -ProbeAll -Ports 22,3389
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidatePattern('^\d{1,3}\.\d{1,3}\.\d{1,3}$')][string]$Subnet,
    [int[]]$Ports = @(22, 445, 3389),
    [switch]$ProbeAll,
    [int]$PingTimeoutMs = 500
)
$ErrorActionPreference = 'SilentlyContinue'

$pings = 1..254 | ForEach-Object { (New-Object System.Net.NetworkInformation.Ping).SendPingAsync("$Subnet.$_", $PingTimeoutMs) }
[Threading.Tasks.Task]::WaitAll($pings)
$alive = $pings | Where-Object { $_.Result.Status -eq 'Success' } | ForEach-Object { $_.Result.Address.IPAddressToString }
$targets = if ($ProbeAll) { 1..254 | ForEach-Object { "$Subnet.$_" } } else { $alive }

$probes = foreach ($ip in $targets) { foreach ($p in $Ports) { $c = New-Object System.Net.Sockets.TcpClient; [pscustomobject]@{ Ip = $ip; Port = $p; Client = $c; Task = $c.ConnectAsync($ip, $p) } } }
Start-Sleep -Seconds 2
$open = @{}
foreach ($pr in $probes) { if ($pr.Task.IsCompleted -and -not $pr.Task.IsFaulted -and $pr.Client.Connected) { $open["$($pr.Ip)"] += @($pr.Port) }; $pr.Client.Dispose() }

$hosts = ($alive + $open.Keys) | Sort-Object -Unique { [version]$_ }
foreach ($ip in $hosts) {
    $name = try { [System.Net.Dns]::GetHostEntry($ip).HostName } catch { '-' }
    [pscustomobject]@{
        Ip    = $ip
        Ping  = ($ip -in $alive)
        Open  = (($open[$ip] | Sort-Object) -join ',')
        Name  = $name
    }
}

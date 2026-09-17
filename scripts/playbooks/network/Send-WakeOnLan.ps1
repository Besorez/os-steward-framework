<#
.SYNOPSIS
    Send a Wake-on-LAN magic packet and optionally wait until the host answers ping.
.PARAMETER Mac
    Target NIC hardware address, colon- or dash-separated.
.PARAMETER Broadcast
    Subnet broadcast address, e.g. 192.0.2.255.
.PARAMETER WaitForHost
    IP or name to ping after sending; the script exits 0 as soon as it answers, 1 on timeout.
.EXAMPLE
    .\Send-WakeOnLan.ps1 -Mac '<peer MAC>' -Broadcast 192.0.2.255 -WaitForHost 192.0.2.51
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidatePattern('^([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}$')][string]$Mac,
    [Parameter(Mandatory)][string]$Broadcast,
    [string]$WaitForHost,
    [int]$TimeoutSeconds = 90,
    [int[]]$Ports = @(7, 9),
    [int]$Repeat = 3
)
$ping = New-Object System.Net.NetworkInformation.Ping
if ($WaitForHost -and $ping.Send($WaitForHost, 800).Status -eq 'Success') { Write-Output "already up: $WaitForHost"; exit 0 }

$bytes  = $Mac -split '[:-]' | ForEach-Object { [byte]('0x' + $_) }
$packet = [byte[]](,0xFF * 6) + ($bytes * 16)
$udp = New-Object System.Net.Sockets.UdpClient
$udp.EnableBroadcast = $true
for ($n = 0; $n -lt $Repeat; $n++) {
    foreach ($port in $Ports) { $udp.Send($packet, $packet.Length, $Broadcast, $port) | Out-Null }
    Start-Sleep -Milliseconds 300
}
$udp.Close()
Write-Output "magic packet sent to $Mac via $Broadcast"
if (-not $WaitForHost) { exit 0 }

$sw = [Diagnostics.Stopwatch]::StartNew()
while ($sw.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
    if ($ping.Send($WaitForHost, 800).Status -eq 'Success') { Write-Output ("UP after {0:N0}s" -f $sw.Elapsed.TotalSeconds); exit 0 }
    Start-Sleep -Seconds 2
}
Write-Output "no answer from $WaitForHost after ${TimeoutSeconds}s (check BIOS wake settings, NIC wake arming, sleep state S3 vs S5)"
exit 1

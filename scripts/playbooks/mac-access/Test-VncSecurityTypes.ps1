<#
.SYNOPSIS
    Read-only RFB probe: print a VNC server's protocol version and the security types it offers, in server order.
.DESCRIPTION
    Opens TCP to the VNC port, reads the version banner, answers RFB 003.008, reads the offered
    security types and disconnects before choosing one (no authentication attempt). Apple Screen
    Sharing announces "RFB 003.889" and offers 30 (ARD, user + password) first; type 2 (VncAuth,
    password only) appears only after a legacy VNC password is set on the Mac.
.PARAMETER HostName
    VNC server, e.g. 192.0.2.40.
.PARAMETER Port
    Default: 5900.
.EXAMPLE
    .\Test-VncSecurityTypes.ps1 -HostName 192.0.2.40
#>
[CmdletBinding()]
param([Parameter(Mandatory)][string]$HostName, [int]$Port = 5900, [int]$TimeoutMs = 5000)
$ErrorActionPreference = 'Stop'
$names = @{ 1 = 'None'; 2 = 'VncAuth (password only)'; 5 = 'RA2'; 6 = 'RA2ne'; 16 = 'Tight'; 18 = 'TLS'; 19 = 'VeNCrypt'
            30 = 'Apple ARD Diffie-Hellman (user + password)'; 33 = 'Apple-specific'; 35 = 'Apple-specific'; 36 = 'Apple-specific' }

function Read-Exact([IO.Stream]$s, [int]$n) {
    $buf = New-Object byte[] $n; $off = 0
    while ($off -lt $n) { $r = $s.Read($buf, $off, $n - $off); if ($r -le 0) { throw 'connection closed by server' }; $off += $r }
    , $buf
}

$tcp = New-Object Net.Sockets.TcpClient
try {
    $tcp.ReceiveTimeout = $TimeoutMs; $tcp.SendTimeout = $TimeoutMs
    $tcp.Connect($HostName, $Port)
    $s = $tcp.GetStream()
    $ver = [Text.Encoding]::ASCII.GetString((Read-Exact $s 12)).Trim()
    Write-Output "server version : $ver$(if ($ver -eq 'RFB 003.889') { '  (Apple Screen Sharing)' })"
    $reply = [Text.Encoding]::ASCII.GetBytes("RFB 003.008`n"); $s.Write($reply, 0, 12)
    $count = (Read-Exact $s 1)[0]
    if ($count -eq 0) {
        $len = Read-Exact $s 4; [Array]::Reverse($len)
        $reason = [Text.Encoding]::ASCII.GetString((Read-Exact $s ([BitConverter]::ToUInt32($len, 0))))
        Write-Output "server refused : $reason"; exit 1
    }
    $types = Read-Exact $s $count
    Write-Output "security types : $($types -join ',')  (server preference order)"
    foreach ($t in $types) { Write-Output ("  {0,3} = {1}" -f $t, $(if ($names.ContainsKey([int]$t)) { $names[[int]$t] } else { 'unknown' })) }
    if ($types -notcontains 2) { Write-Output 'VncAuth (2) not offered: password-only viewers cannot connect; set a legacy VNC password on the Mac.' }
} finally { $tcp.Close() }

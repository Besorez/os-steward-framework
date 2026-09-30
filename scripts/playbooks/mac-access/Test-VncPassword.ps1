<#
.SYNOPSIS
    Read-only check that a VNC password works: complete VncAuth and print the framebuffer size and desktop name.
.DESCRIPTION
    RFB handshake answering 003.008, chooses security type 2 (VncAuth) explicitly, answers the 16-byte
    challenge with DES-ECB keyed by the password (padded to 8 bytes, bits of every key byte reversed),
    reads SecurityResult, sends a shared ClientInit and reads ServerInit. Prints width x height and
    the desktop name, then disconnects. Proves the password and the server side independently of any
    viewer. Exit 1 on failure.
.PARAMETER HostName
    VNC server, e.g. 192.0.2.40.
.PARAMETER PasswordFile
    Plain-text file whose first line is the VNC password (never passed on the command line).
.EXAMPLE
    .\Test-VncPassword.ps1 -HostName 192.0.2.40 -PasswordFile $env:LOCALAPPDATA\OSSteward-playbooks\mac-access\vnc-password.txt
#>
[CmdletBinding()]
param([Parameter(Mandatory)][string]$HostName, [Parameter(Mandatory)][string]$PasswordFile, [int]$Port = 5900, [int]$TimeoutMs = 5000)
$ErrorActionPreference = 'Stop'

function Read-Exact([IO.Stream]$s, [int]$n) {
    $buf = New-Object byte[] $n; $off = 0
    while ($off -lt $n) { $r = $s.Read($buf, $off, $n - $off); if ($r -le 0) { throw 'connection closed by server' }; $off += $r }
    , $buf
}
function Read-U32([IO.Stream]$s) { $b = Read-Exact $s 4; [Array]::Reverse($b); [BitConverter]::ToUInt32($b, 0) }
function Read-U16([IO.Stream]$s) { $b = Read-Exact $s 2; [Array]::Reverse($b); [BitConverter]::ToUInt16($b, 0) }
function Get-BitReversed([byte]$b) { $r = 0; for ($i = 0; $i -lt 8; $i++) { $r = ($r -shl 1) -bor (($b -shr $i) -band 1) }; [byte]$r }

$pw = (Get-Content $PasswordFile -TotalCount 1).Trim()
if ($pw.Length -gt 8) { $pw = $pw.Substring(0, 8) }
$key = New-Object byte[] 8
[Text.Encoding]::ASCII.GetBytes($pw).CopyTo($key, 0)
$key = [byte[]]($key | ForEach-Object { Get-BitReversed $_ })

$tcp = New-Object Net.Sockets.TcpClient
try {
    $tcp.ReceiveTimeout = $TimeoutMs; $tcp.SendTimeout = $TimeoutMs
    $tcp.Connect($HostName, $Port)
    $s = $tcp.GetStream()
    $ver = [Text.Encoding]::ASCII.GetString((Read-Exact $s 12)).Trim()
    $s.Write([Text.Encoding]::ASCII.GetBytes("RFB 003.008`n"), 0, 12)
    $types = Read-Exact $s ((Read-Exact $s 1)[0])
    if ($types -notcontains 2) { Write-Output "server $ver offers $($types -join ',') - no VncAuth (2): set a legacy VNC password on the Mac"; exit 1 }
    $s.WriteByte(2)
    $challenge = Read-Exact $s 16
    $des = [Security.Cryptography.DES]::Create(); $des.Mode = 'ECB'; $des.Padding = 'None'
    $response = $des.CreateEncryptor($key, (New-Object byte[] 8)).TransformFinalBlock($challenge, 0, 16)
    $s.Write($response, 0, 16)
    if ((Read-U32 $s) -ne 0) {
        $reason = try { [Text.Encoding]::ASCII.GetString((Read-Exact $s (Read-U32 $s))) } catch { '' }
        Write-Output "VncAuth FAILED on $ver $reason"; exit 1
    }
    $s.WriteByte(1)                              # ClientInit, shared session
    $w = Read-U16 $s; $h = Read-U16 $s
    [void](Read-Exact $s 16)                     # pixel format
    $name = [Text.Encoding]::UTF8.GetString((Read-Exact $s (Read-U32 $s)))
    Write-Output "VncAuth OK on $ver : framebuffer ${w}x${h}, desktop '$name'"
} finally { $tcp.Close() }

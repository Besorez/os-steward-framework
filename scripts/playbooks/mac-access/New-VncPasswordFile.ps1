<#
.SYNOPSIS
    Write a VNC "vncpasswd" file (8 obfuscated bytes) for viewers such as TigerVNC -PasswordFile=.
.DESCRIPTION
    Reads the plain VNC password from the first line of -PasswordFile (never from the command line).
    When that file does not exist yet, a random 8-character password is generated into it first -
    VncAuth uses at most 8 characters. The output is the classic obfuscation: the password padded
    with zeros to 8 bytes, DES-ECB encrypted with the fixed key 23,82,107,6,35,78,88,7 with the bits
    of every key byte reversed (VNC's DES variant reverses key bits). It is obfuscation, not
    protection: keep both files in a per-user folder, never in a repository.
.PARAMETER PasswordFile
    Plain-text password file, e.g. $env:LOCALAPPDATA\OSSteward-playbooks\mac-access\vnc-password.txt.
.PARAMETER OutFile
    vncpasswd file to write, e.g. $env:LOCALAPPDATA\OSSteward-playbooks\mac-access\mac.vncpasswd.
.EXAMPLE
    $d = "$env:LOCALAPPDATA\OSSteward-playbooks\mac-access"
    .\New-VncPasswordFile.ps1 -PasswordFile $d\vnc-password.txt -OutFile $d\mac.vncpasswd
.NOTES
    Writes files only. Rollback: remove the two files yourself.
#>
[CmdletBinding()]
param([Parameter(Mandatory)][string]$PasswordFile, [Parameter(Mandatory)][string]$OutFile)
$ErrorActionPreference = 'Stop'

function Get-BitReversed([byte]$b) { $r = 0; for ($i = 0; $i -lt 8; $i++) { $r = ($r -shl 1) -bor (($b -shr $i) -band 1) }; [byte]$r }

foreach ($f in $PasswordFile, $OutFile) { $dir = Split-Path -Parent $f; if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null } }
if (-not (Test-Path $PasswordFile)) {
    $chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789'.ToCharArray()
    $rng = [Security.Cryptography.RandomNumberGenerator]::Create(); $bytes = New-Object byte[] 8; $rng.GetBytes($bytes)
    Set-Content -Path $PasswordFile -Value (-join ($bytes | ForEach-Object { $chars[$_ % $chars.Length] })) -Encoding ascii
    Write-Output "generated a new 8-character password into $PasswordFile"
}
$pw = (Get-Content $PasswordFile -TotalCount 1).Trim()
if ($pw.Length -eq 0) { throw 'password file is empty' }
if ($pw.Length -gt 8) { Write-Warning 'VncAuth uses only the first 8 characters'; $pw = $pw.Substring(0, 8) }

$plain = New-Object byte[] 8
[Text.Encoding]::ASCII.GetBytes($pw).CopyTo($plain, 0)
$key = [byte[]](23, 82, 107, 6, 35, 78, 88, 7) | ForEach-Object { Get-BitReversed $_ }
$des = [Security.Cryptography.DES]::Create(); $des.Mode = 'ECB'; $des.Padding = 'None'
$cipher = $des.CreateEncryptor([byte[]]$key, (New-Object byte[] 8)).TransformFinalBlock($plain, 0, 8)
[IO.File]::WriteAllBytes($OutFile, $cipher)
Write-Output "wrote $OutFile (8 bytes)"

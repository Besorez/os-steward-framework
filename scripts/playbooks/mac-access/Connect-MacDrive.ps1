<#
.SYNOPSIS
    Map a Mac SMB share (by default the user's home folder \\host\user) as a persistent drive letter.
.DESCRIPTION
    Asks for the Mac password with Get-Credential (never on a command line), stores it in Windows
    Credential Manager with cmdkey and maps the share with "net use /persistent:yes". Requires
    File Sharing on the Mac AND an SMB-NT hash for the account (enable-smb-sharing.sh); without the
    hash Windows gets "The user name or password is incorrect" with the correct password.
.PARAMETER HostName
    Mac address, e.g. 192.0.2.40 (DHCP-reserved).
.PARAMETER User
    Mac short user name.
.PARAMETER Share
    Share name. Default: the user name (macOS exposes the home folder under it).
.PARAMETER DriveLetter
    Default: M.
.EXAMPLE
    .\Connect-MacDrive.ps1 -HostName 192.0.2.40 -User TestUser
.NOTES
    Rollback: net use M: /delete ; cmdkey /delete:192.0.2.40
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$HostName,
    [Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9._-]+$')][string]$User,
    [string]$Share = '',
    [ValidatePattern('^[D-Zd-z]$')][string]$DriveLetter = 'M'
)
$ErrorActionPreference = 'Stop'
if (-not $Share) { $Share = $User }
$cred = Get-Credential -UserName $User -Message "Mac password for $User (drive ${DriveLetter}:)"
cmdkey /add:$HostName /user:$User /pass:$($cred.GetNetworkCredential().Password) | Out-Null
net use "${DriveLetter}:" "\\$HostName\$Share" /persistent:yes
if ($LASTEXITCODE -ne 0) { throw "net use failed ($LASTEXITCODE). File Sharing on? SMB-NT hash set? (see enable-smb-sharing.sh)" }
if (Test-Path "${DriveLetter}:\") { Write-Output "${DriveLetter}: -> \\$HostName\$Share OK" }

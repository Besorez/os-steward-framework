<#
.SYNOPSIS
    Create (or re-key) a dedicated local account for SMB access with a password generated on this machine.
.DESCRIPTION
    Avoids authenticating shares with a Microsoft account. The password is generated here, applied, and
    printed ONCE as the last output line so a caller over SSH can capture it into a credential store
    without it ever appearing on a command line. Optionally grants full access on the given shares.
.PARAMETER Name
    Local account name (default: share).
.PARAMETER Shares
    Share names to grant Full access on (default: none).
.PARAMETER RemoteDesktopAdmin
    Also add the account to Administrators and Remote Desktop Users (fallback RDP identity).
.NOTES
    Run as administrator. Rollback: Remove-LocalUser -Name <Name>.
#>
[CmdletBinding()]
param(
    [string]$Name = 'share',
    [string[]]$Shares = @(),
    [switch]$RemoteDesktopAdmin,
    [int]$PasswordLength = 24
)
$ErrorActionPreference = 'Stop'
$pw  = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count $PasswordLength | ForEach-Object { [char]$_ })
$sec = ConvertTo-SecureString $pw -AsPlainText -Force
if (Get-LocalUser -Name $Name -ErrorAction SilentlyContinue) {
    Set-LocalUser -Name $Name -Password $sec -PasswordNeverExpires $true
} else {
    New-LocalUser -Name $Name -Password $sec -PasswordNeverExpires -AccountNeverExpires -Description 'Dedicated LAN share account' | Out-Null
}
foreach ($s in $Shares) { Grant-SmbShareAccess -Name $s -AccountName $Name -AccessRight Full -Force | Out-Null }
if ($RemoteDesktopAdmin) {
    foreach ($sid in 'S-1-5-32-544', 'S-1-5-32-555') {
        if (-not (Get-LocalGroupMember -SID $sid -ErrorAction SilentlyContinue | Where-Object Name -like "*\$Name")) { Add-LocalGroupMember -SID $sid -Member $Name }
    }
}
Write-Warning "account '$Name' ready; the password is the last output line - capture it, do not log it"
Write-Output $pw

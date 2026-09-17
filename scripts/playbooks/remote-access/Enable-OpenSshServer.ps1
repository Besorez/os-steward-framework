<#
.SYNOPSIS
    Install and start the OpenSSH server (works on Home editions) with PowerShell as the default shell.
.NOTES
    Run as administrator. Rollback: Stop-Service sshd; Set-Service sshd -StartupType Disabled;
    Remove-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0.
#>
[CmdletBinding()]
param([string]$DefaultShell = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe")
$ErrorActionPreference = 'Stop'
$cap = Get-WindowsCapability -Online -Name 'OpenSSH.Server~~~~0.0.1.0'
if ($cap.State -ne 'Installed') { Add-WindowsCapability -Online -Name 'OpenSSH.Server~~~~0.0.1.0' | Out-Null }
Set-Service sshd -StartupType Automatic
Start-Service sshd
if (-not (Test-Path 'HKLM:\SOFTWARE\OpenSSH')) { New-Item 'HKLM:\SOFTWARE\OpenSSH' | Out-Null }
New-ItemProperty -Path 'HKLM:\SOFTWARE\OpenSSH' -Name DefaultShell -Value $DefaultShell -PropertyType String -Force | Out-Null
Write-Output ("sshd: {0}; default shell: {1}" -f (Get-Service sshd).Status, $DefaultShell)

<#
.SYNOPSIS
    Read-only: installed applications from the Uninstall registry keys with estimated sizes, largest first.
.DESCRIPTION
    The list is the input for "what stays after a reinstall" decisions; pipe to a file and turn the keepers
    into a winget script. Sizes are the installer's EstimatedSize and can be missing.
.EXAMPLE
    .\Get-InstalledApps.ps1 | Format-Table -AutoSize
#>
[CmdletBinding()]
param([int]$Top = 0)
$ErrorActionPreference = 'SilentlyContinue'
$keys = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
$apps = foreach ($k in $keys) {
    Get-ItemProperty $k | Where-Object { $_.DisplayName -and -not $_.SystemComponent } |
        Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, InstallLocation,
            @{n='GB'; e={ if ($_.EstimatedSize) { [math]::Round(($_.EstimatedSize * 1KB)/1GB, 2) } else { $null } }}
}
$apps = $apps | Sort-Object DisplayName -Unique | Sort-Object GB -Descending
if ($Top -gt 0) { $apps | Select-Object -First $Top } else { $apps }

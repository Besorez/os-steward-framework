<#
.SYNOPSIS
    Read-only: fixed volumes with used/free, system files, recycle bins, update cache and WinSxS real size.
#>
[CmdletBinding()]
param()
$ErrorActionPreference = 'SilentlyContinue'
function Sum([string[]]$paths) { (Get-ChildItem -Path $paths -Recurse -Force -File -Attributes !ReparsePoint | Measure-Object Length -Sum).Sum }
'== VOLUMES =='
Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -eq 'Fixed' } | ForEach-Object {
    '{0}: {1,-14} size={2,6} GB  used={3,6} GB  free={4,6} GB' -f $_.DriveLetter, $_.FileSystemLabel, [math]::Round($_.Size/1GB), [math]::Round(($_.Size - $_.SizeRemaining)/1GB), [math]::Round($_.SizeRemaining/1GB)
}
''
'== SYSTEM FILES =='
foreach ($n in 'hiberfil.sys', 'pagefile.sys', 'swapfile.sys') {
    Get-Volume | Where-Object DriveLetter | ForEach-Object { $f = Get-Item "$($_.DriveLetter):\$n" -Force; if ($f) { '{0,7:N1} GB  {1}' -f ($f.Length/1GB), $f.FullName } }
}
$bins = Get-Volume | Where-Object DriveLetter | ForEach-Object { "$($_.DriveLetter):\`$Recycle.Bin" }
'{0,7:N1} GB  recycle bins (all volumes)' -f ((Sum $bins)/1GB)
'{0,7:N1} GB  Windows Update download cache' -f ((Sum "$env:SystemRoot\SoftwareDistribution\Download")/1GB)
'{0,7:N1} GB  WinSxS (real size; shrink only via DISM /StartComponentCleanup)' -f ((Sum "$env:SystemRoot\WinSxS")/1GB)

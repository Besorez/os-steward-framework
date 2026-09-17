<#
.SYNOPSIS
    Read-only: files at or above a size threshold with modification dates, largest first.
.EXAMPLE
    .\Get-LargeFiles.ps1 -Roots D:\, F:\ -MinGB 2
#>
[CmdletBinding()]
param([Parameter(Mandatory)][string[]]$Roots, [double]$MinGB = 2, [int]$Top = 200)
$ErrorActionPreference = 'SilentlyContinue'
$min = [long]($MinGB * 1GB)
Get-ChildItem $Roots -Recurse -Force -File -Attributes !ReparsePoint | Where-Object Length -ge $min |
    Sort-Object Length -Descending | Select-Object -First $Top |
    ForEach-Object { '{0,8:N1} GB  {1:yyyy-MM-dd}  {2}' -f ($_.Length/1GB), $_.LastWriteTime, $_.FullName }

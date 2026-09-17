<#
.SYNOPSIS
    Read-only dry run: operating-system and application caches on the system drive whose CONTENTS are
    safe to clear (recreated on demand), with sizes.
.DESCRIPTION
    Covers temp folders, crash dumps, GPU shader caches, package caches (npm, NuGet, Visual Studio
    Installer), update payloads (Office, Windows Update), browser and chat-client caches, Steam artwork
    cache. Nothing is removed by this script (OSF-INV-001); the owner clears approved folders, then
    Delivery Optimization (Delete-DeliveryOptimizationCache) and DISM /StartComponentCleanup are the
    two remaining, tool-driven steps.
.EXAMPLE
    .\Get-CacheCandidates.ps1
#>
[CmdletBinding()]
param([string]$Profile = $env:USERPROFILE)
$ErrorActionPreference = 'SilentlyContinue'
$L = Join-Path $Profile 'AppData\Local'
$R = Join-Path $Profile 'AppData\Roaming'
$candidates = @(
    @{ Path = "$L\Temp";                                            Note = 'user temp' },
    @{ Path = "$env:SystemRoot\Temp";                               Note = 'system temp' },
    @{ Path = "$L\CrashDumps";                                      Note = 'crash dumps' },
    @{ Path = "$env:ProgramData\Microsoft\Windows\WER";             Note = 'error reports' },
    @{ Path = "$L\NVIDIA\DXCache";                                  Note = 'GPU shader cache' },
    @{ Path = "$L\NVIDIA\GLCache";                                  Note = 'GPU shader cache' },
    @{ Path = "$L\NVIDIA\OptixCache";                               Note = 'GPU shader cache' },
    @{ Path = (Join-Path $Profile 'AppData\LocalLow\NVIDIA');       Note = 'GPU shader cache (per-app)' },
    @{ Path = "$env:ProgramData\NVIDIA Corporation\Downloader";     Note = 'driver installer leftovers' },
    @{ Path = "$L\npm-cache";                                       Note = 'npm cache' },
    @{ Path = "$L\NuGet\v3-cache";                                  Note = 'NuGet cache' },
    @{ Path = "$L\NuGet\plugins-cache";                             Note = 'NuGet cache' },
    @{ Path = "$env:ProgramData\Microsoft\VisualStudio\Packages";   Note = 'VS Installer download cache (re-downloaded on modify/repair)' },
    @{ Path = "${env:ProgramFiles}\Microsoft Office\Updates\Download"; Note = 'Office update payloads' },
    @{ Path = "$env:SystemRoot\SoftwareDistribution\Download";      Note = 'Windows Update payloads' },
    @{ Path = "$env:SystemRoot\Logs\CBS";                           Note = 'servicing logs' },
    @{ Path = "$L\Microsoft\Windows\INetCache";                     Note = 'IE/WebView cache' },
    @{ Path = "$L\Google\Chrome\User Data\Default\Cache";           Note = 'browser cache' },
    @{ Path = "$L\Google\Chrome\User Data\Default\Code Cache";      Note = 'browser cache' },
    @{ Path = "$L\Microsoft\Edge\User Data\Default\Cache";          Note = 'browser cache' },
    @{ Path = "$L\Microsoft\Edge\User Data\Default\Code Cache";     Note = 'browser cache' },
    @{ Path = "$L\slack\Cache";                                     Note = 'chat client cache' },
    @{ Path = "$R\Slack\Cache";                                     Note = 'chat client cache' },
    @{ Path = "${env:ProgramFiles(x86)}\Steam\appcache\librarycache"; Note = 'Steam artwork cache' }
)
function Size([string]$p) { (Get-ChildItem $p -Recurse -Force -File -Attributes !ReparsePoint | Measure-Object Length -Sum).Sum }
$total = 0L
'== CACHE CANDIDATES (dry run, nothing removed; contents only, folders stay) =='
foreach ($c in $candidates) {
    if (-not (Test-Path $c.Path)) { continue }
    $s = Size $c.Path; $total += $s
    '{0,7:N1} GB  {1}  [{2}]' -f ($s/1GB), $c.Path, $c.Note
}
'total: {0:N1} GB' -f ($total/1GB)
'also: Delete-DeliveryOptimizationCache -Force ; Dism /Online /Cleanup-Image /StartComponentCleanup'

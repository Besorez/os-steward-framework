<#
.SYNOPSIS
    Read-only: folders whose NAME marks them as regenerable (build output, caches, temp), with sizes.
.PARAMETER Roots
    Volumes or folders to scan.
.PARAMETER Names
    Folder names that count as junk candidates. Default covers Unreal, Unity, Visual Studio, Node, .NET,
    Gradle, Python and Windows leftovers.
.EXAMPLE
    .\Get-JunkFolders.ps1 -Roots C:\, D:\ -MinMB 200
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string[]]$Roots,
    [string[]]$Names = @('node_modules', 'DerivedDataCache', 'Intermediate', 'Binaries', 'Saved', 'Library', 'Temp', 'tmp', 'cache', 'Cache', '__pycache__', '.gradle', '.nuget', 'Windows.old', '$Recycle.Bin', 'SoftwareDistribution', 'Downloads', 'obj', 'bin', '.vs', 'Crashes', 'Logs'),
    [int]$MinMB = 200,
    [int]$MaxDepth = 10
)
$ErrorActionPreference = 'SilentlyContinue'
$min = [long]$MinMB * 1MB
function Size([string]$p) { $s = 0L; try { foreach ($f in [IO.Directory]::EnumerateFiles($p, '*', 'AllDirectories')) { try { $s += ([IO.FileInfo]$f).Length } catch {} } } catch {}; $s }
$rows = foreach ($r in $Roots) {
    Get-ChildItem $r -Recurse -Directory -Force -Depth $MaxDepth -Attributes !ReparsePoint | Where-Object { $Names -contains $_.Name } | ForEach-Object {
        $s = Size $_.FullName
        if ($s -ge $min) { [pscustomobject]@{ GB = [math]::Round($s/1GB, 1); Path = $_.FullName } }
    }
}
'== JUNK CANDIDATES (by folder name, >= {0} MB) ==' -f $MinMB
$rows | Sort-Object GB -Descending | ForEach-Object { '{0,8:N1} GB  {1}' -f $_.GB, $_.Path }
'total: {0:N1} GB in {1} folders' -f (($rows | Measure-Object GB -Sum).Sum), ($rows | Measure-Object).Count

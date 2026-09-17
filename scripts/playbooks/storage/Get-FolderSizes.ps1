<#
.SYNOPSIS
    Read-only: folder tree by size under a root, junction-safe, down to a given depth.
.DESCRIPTION
    Walks with .NET enumerators (fast, no arrays), skips reparse points so legacy profile junctions are
    not double counted, and prints every folder at or above -MinGB indented by depth.
.EXAMPLE
    .\Get-FolderSizes.ps1 -Path D:\ -MaxDepth 4 -MinGB 1
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Path,
    [int]$MaxDepth = 4,
    [double]$MinGB = 1
)
$ErrorActionPreference = 'SilentlyContinue'
$rows = New-Object System.Collections.Generic.List[object]
$min  = [long]($MinGB * 1GB)
function Walk([string]$p, [int]$depth) {
    $total = 0L
    try {
        foreach ($f in [IO.Directory]::EnumerateFiles($p)) { try { $total += ([IO.FileInfo]$f).Length } catch {} }
        foreach ($d in [IO.Directory]::EnumerateDirectories($p)) {
            if (([IO.DirectoryInfo]$d).Attributes -band [IO.FileAttributes]::ReparsePoint) { continue }
            $sz = Walk $d ($depth + 1)
            $total += $sz
            if ($depth -lt $MaxDepth -and $sz -ge $min) { $rows.Add([pscustomobject]@{ Bytes = $sz; Depth = $depth + 1; Path = $d }) }
        }
    } catch {}
    return $total
}
$sw = [Diagnostics.Stopwatch]::StartNew()
$t = Walk $Path 0
'== {0}  {1:N0} GB  ({2:N0}s) ==' -f $Path, ($t/1GB), $sw.Elapsed.TotalSeconds
$rows | Sort-Object Path | ForEach-Object { '{0,8:N1} GB  {1}{2}' -f ($_.Bytes/1GB), ('  ' * ($_.Depth - 1)), $_.Path }

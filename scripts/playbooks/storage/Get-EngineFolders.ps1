<#
.SYNOPSIS
    Read-only: locate Unreal Engine folders (source checkouts and engine copies inside projects) with sizes.
.DESCRIPTION
    An engine root is an 'Engine' folder that contains Build\BatchFiles. The parent having Setup.bat means
    a source checkout; without it the Engine folder was copied next to a project (delete only the Engine
    folder in that case, never its siblings). Installed launcher engines can be excluded with -Exclude.
.EXAMPLE
    .\Get-EngineFolders.ps1 -Roots D:\, S:\ -Exclude 'S:\UE_Vanilla\*'
#>
[CmdletBinding()]
param([Parameter(Mandatory)][string[]]$Roots, [string[]]$Exclude = @(), [int]$MaxDepth = 5)
$ErrorActionPreference = 'SilentlyContinue'
function Size([string]$p) { $s = 0L; try { foreach ($f in [IO.Directory]::EnumerateFiles($p, '*', 'AllDirectories')) { try { $s += ([IO.FileInfo]$f).Length } catch {} } } catch {}; $s }
foreach ($r in $Roots) {
    Get-ChildItem $r -Recurse -Directory -Force -Depth $MaxDepth -Attributes !ReparsePoint |
        Where-Object { $_.Name -eq 'Engine' -and (Test-Path (Join-Path $_.FullName 'Build\BatchFiles')) } |
        ForEach-Object {
            $full = $_.FullName
            if ($Exclude | Where-Object { $full -like $_ }) { return }
            $parent = $_.Parent.FullName
            [pscustomobject]@{
                GB             = [math]::Round((Size $full)/1GB, 1)
                Engine         = $full
                SourceCheckout = Test-Path (Join-Path $parent 'Setup.bat')
                Siblings       = (Get-ChildItem $parent -Force | Where-Object Name -ne 'Engine' | Select-Object -First 12 -ExpandProperty Name) -join ', '
            }
        }
}

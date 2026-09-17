<#
.SYNOPSIS
    Share every fixed drive under its letter (D: -> \\HOST\D) with full access for one account.
.PARAMETER Account
    Account to grant, e.g. 'HOST\share' (default: the current user).
.NOTES
    Run as administrator. Rollback: Remove-SmbShare -Name <letter>.
#>
[CmdletBinding()]
param([string]$Account = "$env:COMPUTERNAME\$env:USERNAME", [string[]]$Exclude = @())
Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -eq 'Fixed' -and ([string]$_.DriveLetter) -notin $Exclude } | ForEach-Object {
    $l = [string]$_.DriveLetter
    if (Get-SmbShare -Name $l -ErrorAction SilentlyContinue) { Write-Output "$l already shared" }
    else { New-SmbShare -Name $l -Path "${l}:\" -FullAccess $Account | Out-Null; Write-Output "\\$env:COMPUTERNAME\$l -> ${l}:\ (full: $Account)" }
}

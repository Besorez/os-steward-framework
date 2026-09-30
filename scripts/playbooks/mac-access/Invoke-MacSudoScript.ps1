<#
.SYNOPSIS
    Run one of the Mac-side .sh scripts with sudo in its own visible, clearly titled window.
.DESCRIPTION
    sudo over non-interactive ssh fails ("a password is required"), so the script is copied to /tmp on
    the Mac and run through "ssh -t <alias> sudo bash ..." in a NEW console window whose title says
    that it asks for the Mac password. When the remote script ends, the window waits for Enter at a
    Read-Host prompt and closes: anything typed there by mistake is not executed and does not land in
    PSReadLine history (a password typed into a finished, idle PowerShell window does both).
.PARAMETER Alias
    ssh alias of the Mac (see Install-MacSshKey.ps1). Default: mac.
.PARAMETER ScriptPath
    Local .sh file, e.g. .\enable-smb-sharing.sh.
.PARAMETER Arguments
    Optional plain arguments for the script (never passwords).
.EXAMPLE
    .\Invoke-MacSudoScript.ps1 -ScriptPath .\enable-smb-sharing.sh
.NOTES
    Copies to /tmp (cleared by macOS on restart); changes nothing by itself. Rollback: see the .sh script.
#>
[CmdletBinding()]
param(
    [ValidatePattern('^[A-Za-z0-9._-]+$')][string]$Alias = 'mac',
    [Parameter(Mandatory)][string]$ScriptPath,
    [ValidatePattern('^[A-Za-z0-9._ /-]*$')][string]$Arguments = ''
)
$ErrorActionPreference = 'Stop'
$src = (Resolve-Path $ScriptPath).Path
$name = [IO.Path]::GetFileName($src)
$remote = "/tmp/osf-$name"
scp -q $src "${Alias}:$remote"
if ($LASTEXITCODE -ne 0) { throw "scp to $Alias failed" }

$title = "MAC PASSWORD - sudo $name on $Alias"
$cmd = @"
`$host.UI.RawUI.WindowTitle = '$title'
Write-Host 'Type the MAC password when sudo (and the script) ask for it - in THIS window only.' -ForegroundColor Cyan
ssh -t $Alias 'sudo bash $remote $Arguments'
Write-Host "`nexit code: `$LASTEXITCODE" -ForegroundColor Yellow
[void](Read-Host 'Finished. Press Enter to close this window')
"@
$enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($cmd))
Start-Process powershell.exe -ArgumentList '-NoProfile', '-EncodedCommand', $enc
Write-Output "opened window '$title'"

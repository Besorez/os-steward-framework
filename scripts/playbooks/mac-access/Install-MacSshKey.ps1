<#
.SYNOPSIS
    Authorize the operator's SSH key on a Mac (one password prompt), add a Host alias and verify key login.
.DESCRIPTION
    Pipes the operator's public key over ssh into ~/.ssh/authorized_keys on the Mac (Remote Login must
    be on), adds a "Host <Alias>" block to the operator's ~/.ssh/config when missing, then verifies with
    BatchMode (no password allowed) and prints the Mac's hostname and macOS version.
.PARAMETER HostName
    Mac address or name, e.g. 192.0.2.40 (prefer a DHCP-reserved address over the .local name).
.PARAMETER User
    Mac short user name (Terminal on the Mac: whoami).
.PARAMETER Alias
    Host alias to create in ~/.ssh/config. Default: mac.
.PARAMETER PublicKeyPath
    Default: ~/.ssh/id_ed25519.pub (create with: ssh-keygen -t ed25519).
.EXAMPLE
    .\Install-MacSshKey.ps1 -HostName 192.0.2.40 -User TestUser
.NOTES
    Rollback: remove the key line from ~/.ssh/authorized_keys on the Mac and the Host block from
    ~/.ssh/config on the operator.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$HostName,
    [Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9._-]+$')][string]$User,
    [ValidatePattern('^[A-Za-z0-9._-]+$')][string]$Alias = 'mac',
    [string]$PublicKeyPath = "$env:USERPROFILE\.ssh\id_ed25519.pub"
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path $PublicKeyPath)) { throw "No public key at $PublicKeyPath. Create one first: ssh-keygen -t ed25519" }
$pub = (Get-Content $PublicKeyPath -Raw).Trim()

ssh -o BatchMode=yes -o LogLevel=QUIET -o StrictHostKeyChecking=accept-new "$User@$HostName" 'true'
if ($LASTEXITCODE -eq 0) { Write-Output 'key login already works; key not pushed again' }
else {
    Write-Host "Mac password for $User (asked once, by ssh):" -ForegroundColor Cyan
    # no double quotes in the remote command: Windows PowerShell 5.1 mangles them for native programs
    $pub | ssh -o StrictHostKeyChecking=accept-new "$User@$HostName" 'mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys'
    if ($LASTEXITCODE -ne 0) { throw "ssh exited with $LASTEXITCODE (Remote Login on? right user/password?)" }
}

$cfg = "$env:USERPROFILE\.ssh\config"
$hasAlias = (Test-Path $cfg) -and (Select-String -Path $cfg -Pattern "^\s*Host\s+$([regex]::Escape($Alias))\s*$" -Quiet)
if (-not $hasAlias) {
    $block = "`r`nHost $Alias`r`n    HostName $HostName`r`n    User $User`r`n    IdentityFile ~/.ssh/id_ed25519`r`n    StrictHostKeyChecking accept-new`r`n"
    Add-Content -Path $cfg -Value $block -Encoding ascii
    Write-Output "added 'Host $Alias' to $cfg"
} else { Write-Output "'Host $Alias' already in $cfg (left unchanged)" }

ssh -o BatchMode=yes $Alias 'echo KEY-OK: $(hostname) macOS $(sw_vers -productVersion)'
if ($LASTEXITCODE -ne 0) { throw "key login failed for alias '$Alias'" }

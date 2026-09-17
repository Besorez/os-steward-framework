<#
.SYNOPSIS
    Authorize a public key for administrators over SSH (administrators_authorized_keys with the ACL sshd requires).
.PARAMETER PublicKey
    One OpenSSH public key line ("ssh-ed25519 AAAA... comment").
.NOTES
    Run as administrator on the target. sshd silently ignores the file unless its ACL is exactly
    Administrators + SYSTEM. Rollback: remove the line from the file.
#>
[CmdletBinding()]
param([Parameter(Mandatory)][ValidatePattern('^(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp\d+) AAAA')][string]$PublicKey)
$ErrorActionPreference = 'Stop'
$file = "$env:ProgramData\ssh\administrators_authorized_keys"
if ((Test-Path $file) -and (Get-Content $file | Where-Object { $_ -eq $PublicKey })) { Write-Output 'key already present'; return }
Add-Content -Path $file -Value $PublicKey -Encoding ascii
icacls $file /inheritance:r /grant 'Administrators:F' /grant 'SYSTEM:F' | Out-Null
Restart-Service sshd
Write-Output "key added; $((Get-Content $file | Measure-Object).Count) key(s) authorized"

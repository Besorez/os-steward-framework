<#
.SYNOPSIS
    Stop a machine that is administered remotely from sleeping or hibernating on its own while on AC power.
.NOTES
    Run as administrator. Rollback: powercfg /change standby-timeout-ac <minutes>.
    Coordinated sleep/wake with a peer machine is handled by ../power/ instead.
#>
[CmdletBinding()]
param()
powercfg /change standby-timeout-ac 0
powercfg /change hibernate-timeout-ac 0
Write-Output 'standby/hibernate timeouts on AC set to never'

<#
.SYNOPSIS
    Stop Windows from re-sleeping a machine 2 minutes after a network wake, and stop the HDD spin-down cycle.
.DESCRIPTION
    Run as administrator on the peer. Sets, on the active power scheme (AC and DC):
      - "System unattended sleep timeout" (hidden, 7bc4a2f9-...) -> 0 (never). After a wake that no
        human caused (Wake-on-LAN, pattern match, timer) Windows otherwise sleeps again after 120 s
        regardless of the normal sleep timeout. With 0, the sleep policy belongs to the watchdog.
      - "Turn off hard disk after" (DISKIDLE) -> $DiskIdleSeconds (default 0 = never).
    Prints the previous values first so they can be restored with -UnattendedSeconds / -DiskIdleSeconds.
    Windows default: unattended 120, disk idle 1200.
#>
[CmdletBinding()]
param([int]$UnattendedSeconds = 0, [int]$DiskIdleSeconds = 0)
$unatt = '7bc4a2f9-d8fc-4469-b07b-33eb785aaca0'
powercfg /attributes SUB_SLEEP $unatt -ATTRIB_HIDE
'before:'
powercfg /q SCHEME_CURRENT SUB_SLEEP $unatt | Select-String 'Current'
powercfg /q SCHEME_CURRENT SUB_DISK DISKIDLE | Select-String 'Current'
powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP $unatt $UnattendedSeconds
powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP $unatt $UnattendedSeconds
powercfg /setacvalueindex SCHEME_CURRENT SUB_DISK DISKIDLE $DiskIdleSeconds
powercfg /setdcvalueindex SCHEME_CURRENT SUB_DISK DISKIDLE $DiskIdleSeconds
powercfg /setactive SCHEME_CURRENT
'after (unattended, disk idle):'
powercfg /q SCHEME_CURRENT SUB_SLEEP $unatt | Select-String 'Current'
powercfg /q SCHEME_CURRENT SUB_DISK DISKIDLE | Select-String 'Current'

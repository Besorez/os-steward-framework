<#
.SYNOPSIS
    Read-only: how often the machine slept and woke recently, why it slept, and what woke it last.
.DESCRIPTION
    Counts Kernel-Power 42 (entering sleep) per day, lists the latest sleep/wake events with the
    sleep reason, and prints powercfg /lastwake. The signature of the wake/idle-sleep ping-pong is
    dozens of sleeps per day with "Sleep Reason: System Idle" arriving 2-3 minutes after each
    Power-Troubleshooter 1 (resume), while the regular sleep timeout is set to Never.
    Reasons are matched in English only; on localized Windows read the Message column.
#>
[CmdletBinding()]
param([int]$Days = 3, [int]$Last = 30)
$ev = Get-WinEvent -FilterHashtable @{ LogName = 'System'; Id = 1, 42, 107; StartTime = (Get-Date).AddDays(-$Days) } -ErrorAction SilentlyContinue |
    Where-Object { $_.ProviderName -match 'Kernel-Power|Power-Troubleshooter' }
"sleeps per day (Kernel-Power 42), last $Days days:"
$ev | Where-Object Id -eq 42 | Group-Object { $_.TimeCreated.ToString('yyyy-MM-dd') } | ForEach-Object { "  $($_.Name)  $($_.Count)" }
''
"latest $Last events (1 = resumed, 42 = entering sleep, 107 = resumed from sleep):"
$ev | Select-Object -First $Last | ForEach-Object {
    $reason = ($_.Message -split "`n" | Select-String 'Sleep Reason|Wake Source') -join ' | '
    '  {0}  {1,3}  {2}' -f $_.TimeCreated.ToString('MM-dd HH:mm:ss'), $_.Id, $reason.Trim()
}
''
'last wake source:'; powercfg /lastwake
'wake-armed devices:'; powercfg /devicequery wake_armed

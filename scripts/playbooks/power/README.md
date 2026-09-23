# power/

A secondary machine that sleeps and wakes together with the primary one.
Case: [Paired-Power-Management](../../../docs/playbooks/Paired-Power-Management.md).
Everything is reversible (scheduled tasks + NIC wake setting); logs go to
`%LOCALAPPDATA%\OSSteward-playbooks\power-link.log` (primary) and
`%ProgramData%\OSSteward-playbooks\power.log` (peer).

| Where | Script | What it does |
|---|---|---|
| peer, admin | [Enable-NicWake.ps1](Enable-NicWake.ps1) | Arm the wired NIC for magic-packet wake; expect the SSH session that runs it to drop |
| peer, admin | [Install-SleepWatchdogTask.ps1](Install-SleepWatchdogTask.ps1) | Copies the two scripts below to ProgramData and registers the watchdog every 5 min as SYSTEM |
| peer (installed copy) | [Sleep-Watchdog.ps1](Sleep-Watchdog.ps1) | Sleep when the primary is unreachable for the grace period and no session is Active; opt-out sentinel `keep-awake` |
| peer (installed copy) | [Suspend-Computer.ps1](Suspend-Computer.ps1) | Enter S3 now even with hibernation enabled; what the primary calls over SSH |
| peer, admin | [Set-UnattendedIdlePolicy.ps1](Set-UnattendedIdlePolicy.ps1) | Unattended sleep timeout (hidden, default 120 s) and HDD spin-down to never, so only the watchdog sleeps the peer |
| peer, admin | [Set-WakeOnMagicOnly.ps1](Set-WakeOnMagicOnly.ps1) | Pattern-match wake off (driver + NDIS), EEE off, stray wake devices disarmed; only a magic packet wakes the peer |
| any, read-only | [Get-SleepWakeHistory.ps1](Get-SleepWakeHistory.ps1) | Sleeps per day, sleep reasons, last wake source; spots the wake/idle-sleep ping-pong |
| primary, user | [Install-WakePeerTask.ps1](Install-WakePeerTask.ps1) | Task "Peer Wake": at logon + on resume (Power-Troubleshooter event 1) → [Wake-Peer.ps1](Wake-Peer.ps1) → [../network/Send-WakeOnLan.ps1](../network/Send-WakeOnLan.ps1) |
| primary, user | [Install-SleepPeerTask.ps1](Install-SleepPeerTask.ps1) | Task "Peer Sleep": on entering sleep (Kernel-Power event 42) → [Sleep-Peer.ps1](Sleep-Peer.ps1) → SSH → `Suspend-Computer.ps1` on the peer |

Order: `Enable-NicWake`, `Set-UnattendedIdlePolicy`, `Set-WakeOnMagicOnly` and
`Install-SleepWatchdogTask` on the peer, then
the two installers on the primary, then the verification steps in the
playbook (sleep → ping times out → wake → SSH back).

# Playbook: Paired Power Management

> **Status: Current** (field-verified 2026-09: sleep over SSH, Wake-on-LAN
> from S3 answered in ~8 s). Primary machine: Windows 11. Peer: Windows 10
> workstation on the same LAN, wired, Intel NIC.

## Goal

The peer machine (a build/storage box) should sleep when the primary
machine sleeps and wake when the primary logs on or resumes — without the
owner remembering to do anything, and without the peer sleeping while
someone is actually using it.

## Design

Three cooperating pieces; each alone is insufficient.

| Piece | Where | Trigger | Action |
|---|---|---|---|
| **Wake** | primary, scheduled task, user context | *At logon*; System log event **Microsoft-Windows-Power-Troubleshooter / 1** (resumed from sleep) | `Send-WakeOnLan.ps1` — magic packet to the broadcast address, ports 7 and 9, repeated three times; then wait for ping |
| **Sleep, fast path** | primary, scheduled task | System log event **Microsoft-Windows-Kernel-Power / 42** (entering sleep) | `ssh peer powershell -File Suspend-Computer.ps1` with 3 s connect timeout |
| **Sleep, guaranteed path** | peer, scheduled task as SYSTEM every 5 min | timer | `Sleep-Watchdog.ps1`: sleep if the primary has not answered ping for 10 min *and* no session is `Active` |

Why both sleep paths: Windows logs event 42 and suspends immediately; the
task usually gets its second, but not always, and it never fires when the
primary is powered off by button or crashes. The watchdog covers those.

## Details that made it work

- **Force S3, not hibernate.** With hibernation/Fast Startup enabled,
  `rundll32 powrprof.dll,SetSuspendState 0,1,0` hibernates. Use
  `[System.Windows.Forms.Application]::SetSuspendState('Suspend', $false, $false)`
  from a script file. Works from the SSH service session; the SSH client
  then exits 255 because the host vanished — that is success, not failure.
- **Script files, not inline commands.** `$false` and quotes inside an
  `ssh host 'powershell -Command "…"'` string get mangled somewhere between
  the local shell, ssh and the remote PowerShell (`\False` in the parse
  error). Everything the peer runs lives in a file on the peer.
- **Arm the NIC once**: `Set-NetAdapterPowerManagement -WakeOnMagicPacket Enabled`,
  `powercfg /deviceenablewake "<NIC description>"`, and check with
  `powercfg /devicequery wake_armed`. Changing NIC power management resets
  the adapter and drops the SSH session that issued it — issue it last, or
  expect to reconnect.
- **Watchdog guards**: skip for 5 min after boot or resume (Power-Troubleshooter
  event 1), skip if `qwinsta` shows any `Active` session (local console or a
  connected RDP session — disconnected ones are `Disc` and do not count),
  skip while the sentinel file `C:\Temp\keep-awake` exists. The sentinel is
  the opt-out for the day the peer starts hosting a VPN endpoint or a game
  server and must stay up alone.
- **Peer address stability**: the primary's tasks ping/wake by IP and
  hostname; a DHCP reservation for both machines keeps them valid.
- Wake from S5 (full shutdown) was not verified on the hardware in the
  case; the playbook is stated for S3. Do not shut the peer down, sleep it.

## Failure mode: the wake / idle-sleep ping-pong

> Field-verified 2026-09, a week after the setup above: ~40 sleep/wake
> cycles per day on the peer; the owner noticed that the box kept dropping
> off and woke up on the first access to its shared HDD.

**Evidence** ([Get-SleepWakeHistory.ps1](../../scripts/playbooks/power/Get-SleepWakeHistory.ps1)):
dozens of Kernel-Power 42 per day, almost all `Sleep Reason: System Idle`,
each 2–3 minutes after a Power-Troubleshooter 1; `powercfg /lastwake`
names the NIC; the plan's normal sleep timeout (STANDBYIDLE) is **0 / Never**.
Only a handful of sleeps came from the watchdog (its own log).

**Mechanism.** Two defaults combine:
1. *Wake on Pattern Match* is on in the NIC driver and in NDIS. An SMB
   connection attempt, name resolution or other LAN traffic addressed to
   the sleeping box wakes it. (Enabling magic-packet wake does not turn
   this off; it was already on.)
2. After a wake that no human caused, Windows is in the *unattended* state
   and uses the hidden **System unattended sleep timeout**
   (`7bc4a2f9-d8fc-4469-b07b-33eb785aaca0`, default 120 s) — not the normal
   sleep timeout. With no input and no power request (an SMB session does
   not hold one), the box sleeps again two minutes later.

Add a 20-minute HDD spin-down (DISKIDLE 1200) and the data disk also goes
through a start/stop cycle with every round.

**Fix** (both reversible, on the peer, as admin):
- [Set-UnattendedIdlePolicy.ps1](../../scripts/playbooks/power/Set-UnattendedIdlePolicy.ps1) —
  unattended timeout 0 and disk idle 0, so the watchdog is the only thing
  that decides when the peer sleeps.
- [Set-WakeOnMagicOnly.ps1](../../scripts/playbooks/power/Set-WakeOnMagicOnly.ps1) —
  pattern wake off (driver *and* `Set-NetAdapterPowerManagement`; the
  driver keyword alone leaves NDIS reporting it enabled), EEE off, stray
  wake-armed devices (a GPU USB-C controller in the case) disarmed. Only the
  primary's magic packet wakes the peer now.

Order matters: set the unattended timeout **first**. Disabling pattern wake
alone still leaves every magic-packet wake ending in a 2-minute re-sleep
whenever the primary is not reachable over ping at that moment.

## Verification

1. With no `Active` session on the peer: run the sleep script → ping times
   out within ~25 s (Kernel-Power 42 appears in the peer's System log on
   the next check).
2. Run the wake script → `UP after Ns` in the log; SSH answers.
3. Put the primary to sleep and back: the primary's task log shows
   `sleep sent` and later `wake: UP`; the peer's watchdog log stays silent.

## Rollback

`Unregister-ScheduledTask` for the three tasks; the NIC settings are the
Windows defaults plus magic-packet wake and can be reverted with the same
cmdlets. No persistent system state beyond the tasks and two log files.

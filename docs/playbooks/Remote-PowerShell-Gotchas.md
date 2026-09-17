# Playbook: Remote PowerShell Gotchas

> **Status: Current** (each item was hit and confirmed 2026-09 while driving
> a Windows 10 machine over OpenSSH from Windows 11 with Windows PowerShell
> 5.1 on both ends).

Short, symptom → cause → rule. Read before writing a script that will run
on *another* Windows machine.

## Encoding and files

- **Parse errors on a script that runs fine locally** (`Unexpected token`,
  `Missing closing ')'`, garbage where a string literal should be).
  Windows PowerShell 5.1 reads a `.ps1` without a BOM in the *system ANSI
  code page*; on a non-English Windows the code page differs from the
  author's, and any non-ASCII character in a string breaks the parse.
  **Rule:** scripts for other machines are ASCII-only, or saved as UTF-8
  *with BOM*.
- **`Get-Volume` labels and firewall rule names come back as mojibake** in
  SSH output — cosmetic, the same code-page mismatch on the way out. Do not
  match on localized display names (next section).

## Localized Windows

- `Enable-NetFirewallRule -DisplayGroup 'File and Printer Sharing'` → *No
  MSFT_NetFirewallRule objects found*. Display groups are localized.
  **Rule:** address firewall groups by resource ID:
  `-Group '@FirewallAPI.dll,-28502'` (File and Printer Sharing),
  `-32752` (Network Discovery), `-28752` (Remote Desktop).
- Local groups: use SIDs (`Get-LocalGroup -SID S-1-5-32-544` Administrators,
  `S-1-5-32-555` Remote Desktop Users), never the English names.
- Performance counters (`\PhysicalDisk(*)\% Disk Time`) are localized as
  well; expect an empty result and say so (the framework's own collectors
  report `disk:NotAvailable`).

## Quoting over SSH

- `ssh host 'powershell -Command "… $false …"'` arrives on the remote side
  as `\False`: three shells touch the string (local PowerShell, ssh, remote
  PowerShell as default shell). **Rule:** anything longer than one cmdlet
  goes into a script file copied with `scp`, executed with
  `powershell -NoProfile -ExecutionPolicy Bypass -File …`.
- `Start-Process powershell -ArgumentList "-File …"` launched through SSH
  started a **bare** `powershell.exe` (arguments lost) and the "scan" ran
  for 20 minutes doing nothing. Verify the child's command line with
  `Get-CimInstance Win32_Process | Select CommandLine` before trusting a
  detached job; simpler: run the job in the SSH session itself and keep
  the client in the background.
- A remote command that includes `Remove-*`, `Stop-Process`, registry
  writes or `/delete` may be blocked by the *operator's* tool guard on the
  basis of command text alone (this repository's safety hook does exactly
  that). The rule is not to circumvent it: put the owner-approved action in
  a file the owner runs, or have the owner run the command.

## Sessions and connectivity

- `Set-NetAdapterPowerManagement` / `Enable-NetAdapterPowerManagement`
  reset the adapter and drop the SSH session that issued them. Issue them
  last, expect exit 255, reconnect, verify.
- A machine entering sleep on command makes `ssh` exit **255** with
  *server not responding* — that is the success signal for a sleep script.
- `ssh -o BatchMode=yes` turns any prompt (host key, password) into an
  immediate failure instead of a hang; combine with `ConnectTimeout` and
  `StrictHostKeyChecking accept-new` in the client config.
- Windows Update reboots happen under you. Before declaring a host down,
  check whether the RDP/SMB ports still answer while SSH does not: the
  service starts in a different order after reboot.

## Measuring

- Legacy junctions in a profile (`Application Data`, `Local Settings`,
  `AppData\Local\Application Data`) point back into the profile and inflate
  totals. Size with `-Attributes !ReparsePoint` or skip reparse points.
- `Get-ChildItem -Depth N` is relative to the root you pass; a nested
  engine or project four levels deep needs `-Depth 4` *from that drive*.
- `Measure-Object -Sum` over millions of files is fine; enumerating with
  `[IO.Directory]::EnumerateFiles` is faster and does not build arrays.

## Accounts

- `net user <name> <password>` on a Microsoft-connected account fails with
  **system error 8646** — the local machine is not authoritative. Only a
  local password logon (or the account's conversion to a local account)
  changes what NLA validates against.
- `cmdkey /add … /pass:<pw>` writes the secret into PowerShell history
  (`ConsoleHost_history.txt`). Read the password with `Read-Host
  -AsSecureString` into a variable and pass the variable, or let the target
  generate the secret and return it over the SSH channel.
- Generic `Domain:target=<host>` credentials are consumed by RDP too;
  keep RDP identities under `TERMSRV/<host>`.

## Scheduled tasks

- `New-ScheduledTaskTrigger` has no event trigger; build
  `MSFT_TaskEventTrigger` through `New-CimInstance` with an XPath
  `Subscription`. Useful System-log events: Kernel-Power **42** (entering
  sleep), Power-Troubleshooter **1** (resumed), Kernel-Power **41**
  (unexpected shutdown).
- Register repetition as `-Once -At <midnight> -RepetitionInterval` — a
  daily trigger with repetition stops at the end of the day.

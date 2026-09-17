# network/

Read-only discovery and Wake-on-LAN. Case: [Remote-Windows-Machine-Access](../../../docs/playbooks/Remote-Windows-Machine-Access.md) §1,
[Paired-Power-Management](../../../docs/playbooks/Paired-Power-Management.md).

| Script | Kind | What it does | Example |
|---|---|---|---|
| [Test-LanHosts.ps1](Test-LanHosts.ps1) | read-only | Parallel ping sweep of a /24, TCP probe of SSH/SMB/RDP, reverse DNS; `-ProbeAll` for hosts that drop ICMP | `.\Test-LanHosts.ps1 -Subnet 192.0.2` |
| [Send-WakeOnLan.ps1](Send-WakeOnLan.ps1) | reversible | Magic packet (ports 7 and 9, repeated) to the subnet broadcast, optional wait for ping; exit 1 on timeout | `.\Send-WakeOnLan.ps1 -Mac '<peer MAC>' -Broadcast 192.0.2.255 -WaitForHost 192.0.2.51` |

When the sweep shows nothing but the operator itself and `ping` says
"General failure" even for the router, the operator's own VPN kill-switch
is blocking the LAN — see the playbook.

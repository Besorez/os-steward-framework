# steamos/

Bash scripts run **on the Steam Deck** (copy them over with `scp`). Case:
[Native-Linux-Port-On-SteamOS](../../../docs/playbooks/Native-Linux-Port-On-SteamOS.md).

| Script | Kind | What it does | Example |
|---|---|---|---|
| [check-glibc-needs.sh](check-glibc-needs.sh) | read-only | Highest `GLIBC_` / `GLIBCXX_` version the build's ELF files need vs the system's; exit 1 = private runtime needed | `bash check-glibc-needs.sh ~/Games/SomePort/build` |
| [build-private-glibc.sh](build-private-glibc.sh) | reversible | Current glibc + libgcc + libstdc++ from Arch core into one folder | `bash build-private-glibc.sh ~/Games/SomePort/runtime` |
| [new-port-launcher.sh](new-port-launcher.sh) | reversible | Steam launcher that starts the binary through the private loader; symlinks plugins/config next to the loader | `bash new-port-launcher.sh ~/Games/SomePort/SomePort ~/Games/SomePort/build ~/Games/SomePort/runtime someport` |

Keep the Deck awake during a long copy:
`nohup systemd-inhibit --what=sleep:idle --why=copy sleep 3h &` (release with `pkill -x systemd-inhibit`).

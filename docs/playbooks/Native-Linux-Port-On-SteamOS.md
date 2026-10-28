# Playbook: Native Linux Port On SteamOS

> **Status: Current** (field-verified 2026-10). Steam Deck, SteamOS 3.8
> (glibc 2.41), Windows operator machine on the same LAN with SSH key login
> to the Deck. The port: a recompiled console title shipped as a Linux
> x86-64 tarball, built on a rolling distribution. Host names are
> placeholders (`steamdeck`), user `deck`.
> Scripts: [`scripts/playbooks/steamos/`](../../scripts/playbooks/steamos/README.md).

## Goal

A native Linux build from a release page runs from the Steam library in game
mode, with the owner's own game data imported, without changing the
read-only SteamOS system image.

## 1. Install the build

1. Download on the Deck itself (`curl -L` the release asset), compare the
   SHA-256 with the digest the release page lists, unpack under `~/Games/<port>`.
2. Read the bundled README / run script before anything else: it names the
   expected game-data source (region, title ID), the import tool and the
   exact command line the binary wants.
3. Copy the owner's game data from the operator machine with `scp`. A
   multi-gigabyte copy over Wi-Fi outlives the Deck's idle timeout - the
   symptom is *"Connection timed out"* on port 22 and *"scp: Connection
   closed"* within seconds. Hold sleep for the copy:
   `nohup systemd-inhibit --what=sleep:idle --why=copy sleep 3h &`, release
   with `pkill -x systemd-inhibit` afterwards.
4. Point import tools at a temporary directory on disk
   (`TMPDIR=~/Games/<port>/tmp`): `/tmp` on SteamOS is RAM-backed, and a
   disc rip extracted there competes with the game for memory.

## 2. "version `GLIBC_2.xx' not found"

| Evidence (launch log) | Meaning |
|---|---|
| `/usr/lib/libm.so.6: version 'GLIBC_2.44' not found` | the build needs a newer glibc than SteamOS ships |
| `/usr/lib/libstdc++.so.6: version 'GLIBCXX_3.4.36' not found` | same for libstdc++ |

`check-glibc-needs.sh <build-dir>` states it before the first launch.

Options, cheapest first:

| Option | Trade-off |
|---|---|
| **Private runtime**: current glibc + libstdc++ in a folder, binary started through that folder's `ld-linux-x86-64.so.2 --library-path` | ~8 MB, no system change, GPU driver and display libraries still from `/usr/lib` (older glibc consumers run on a newer glibc). Chosen. |
| Container (distrobox/podman with a rolling image) | works, but gigabytes and GPU/gamescope passthrough to verify |
| Steam Linux Runtime | its glibc is older than SteamOS's - does not help |
| Unlocking the system image to upgrade glibc | reverted by the next SteamOS update, and risks the whole OS |

`build-private-glibc.sh <runtime-dir>` fetches the three Arch core packages
(`glibc`, `libgcc`, `libstdc++` - Arch splits `gcc-libs`; the `+` is
URL-encoded in the mirror index) and keeps only the shared objects.

## 3. Started via the loader: "plugin not found next to the executable"

Through an explicit loader, `/proc/self/exe` is the loader, so a port that
resolves files relative to its executable looks in the runtime folder:

| Evidence | Meaning |
|---|---|
| `GPU plugin 'xenos' not found at <runtime-dir>/librexgpu-xenos.so` | plugin lookup uses the executable's directory |

Symlink the build's `*.so`, `*.toml` and `config/` into the runtime folder.
`new-port-launcher.sh` does that and writes the launcher Steam starts.
Success signal in game mode: `[Gamescope WSI] Created swapchain` in the
launch log and the process steady on CPU. Harmless noise:
`gameoverlayrenderer.so ... wrong ELF class: ELFCLASS32` (Steam preloads
both overlay builds).

## 4. Add to Steam

Add the launcher as a non-Steam game through the running client
(`steam://addnonsteamgame`, permitted only while `/tmp/addnonsteamgamefile`
exists) rather than editing `shortcuts.vdf`, which the client rewrites.
Start it once with `steam steam://rungameid/<game id>` to verify.

## Traps

- `pkill -f <name>` over SSH matches the SSH command line itself and kills
  the session (exit 255). Use `pkill -x` or `pgrep` with an exact name.
- Leftovers the owner removes: the copied source archive (same size as the
  game) and the empty import temp directory; `/tmp` empties on reboot.
- Performance of recompiled console titles is the port's, not the Deck's
  setup: check the port's own notes before tuning anything.

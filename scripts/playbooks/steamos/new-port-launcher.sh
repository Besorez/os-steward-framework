#!/usr/bin/env bash
# new-port-launcher.sh - reversible (writes one launcher file and a few symlinks).
#
# Purpose: write the launcher Steam (game mode) starts for a native port that
#          runs through a private glibc (build-private-glibc.sh). Started via
#          the loader, the program's /proc/self/exe is the loader, so anything
#          the port looks up "next to the executable" (GPU plugins, its .toml,
#          config/) is looked up in the runtime folder: those are symlinked there.
# Usage:   new-port-launcher.sh <launcher> <build-dir> <runtime-dir> <binary> [args...]
# Example: new-port-launcher.sh ~/Games/SomePort/SomePort ~/Games/SomePort/build \
#            ~/Games/SomePort/runtime someport --game_data_root=assets
#          then add <launcher> to Steam as a non-Steam game.
# Rollback: remove the launcher and the symlinks in <runtime-dir> (owner-executed).
set -euo pipefail

[ $# -ge 4 ] || { sed -n '2,15p' "$0"; exit 2; }
LAUNCHER="$1"; BUILD="$(readlink -f "$2")"; RT="$(readlink -f "$3")"; BIN="$4"; shift 4
[ -x "$RT/ld-linux-x86-64.so.2" ] || { echo "no loader in $RT" >&2; exit 1; }
[ -f "$BUILD/$BIN" ] || { echo "no $BIN in $BUILD" >&2; exit 1; }

# Everything the port may resolve relative to its executable.
for f in "$BUILD"/*.so "$BUILD"/*.toml "$BUILD"/config; do
  [ -e "$f" ] && ln -sfn "$f" "$RT/$(basename "$f")"
done

ARGS=""; for a in "$@"; do ARGS+=" $(printf '%q' "$a")"; done
cat > "$LAUNCHER" <<EOF
#!/bin/bash
# Started by Steam. Runs $BIN under the private glibc in $RT.
exec >>"\$(dirname "\$(readlink -f "\$0")")/launch.log" 2>&1
echo "=== \$(date "+%F %T") launch \$*"
cd "$BUILD"
exec "$RT/ld-linux-x86-64.so.2" --library-path "$RT:$BUILD:/usr/lib" "./$BIN"$ARGS "\$@"
EOF
chmod +x "$LAUNCHER"
echo "launcher written: $LAUNCHER"

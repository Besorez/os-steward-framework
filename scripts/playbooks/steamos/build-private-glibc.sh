#!/usr/bin/env bash
# build-private-glibc.sh - reversible (creates one folder; the system is untouched).
#
# Purpose: put a current glibc + libgcc + libstdc++ (Arch Linux core packages)
#          into a private folder, so a build that needs a newer glibc than
#          SteamOS ships can be started through that folder's loader:
#            <dir>/ld-linux-x86-64.so.2 --library-path "<dir>:<build>:/usr/lib" ./game
#          System libraries (Mesa/Vulkan, X11, Wayland) still come from /usr/lib;
#          they were built against an older glibc, which the newer one serves.
# Usage:   build-private-glibc.sh <runtime-dir> [mirror]
# Example: build-private-glibc.sh ~/Games/SomePort/runtime
# Rollback: remove <runtime-dir> (owner-executed).
set -euo pipefail

OUT="${1:-}"
MIRROR="${2:-https://geo.mirror.pkgbuild.com/core/os/x86_64}"
[ -n "$OUT" ] || { echo "usage: $0 <runtime-dir> [mirror]" >&2; exit 2; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/private-glibc.XXXXXX")"
INDEX="$(curl -sSf "$MIRROR/")"
# Arch splits gcc-libs; libstdc++ appears URL-encoded (libstdc%2B%2B).
for PKG in glibc libgcc 'libstdc%2B%2B'; do
  FILE="$(grep -oE "\"$PKG-[0-9][^\"]*-x86_64\.pkg\.tar\.zst\"" <<<"$INDEX" | tr -d '"' | sort -V | tail -1)"
  [ -n "$FILE" ] || { echo "package $PKG not on $MIRROR" >&2; exit 1; }
  echo "fetching $FILE"
  curl -sSfL -o "$WORK/pkg.tar.zst" "$MIRROR/$FILE"
  # Only the shared objects: glibc's usr/lib/getconf entries are hard links
  # into usr/bin and make a plain "usr/lib" extraction fail.
  tar --zstd -xf "$WORK/pkg.tar.zst" -C "$WORK" --wildcards 'usr/lib/*.so*'
done

mkdir -p "$OUT"
cd "$WORK/usr/lib"
cp -aL ld-linux-x86-64.so.2 libc.so.6 libm.so.6 libmvec.so.1 libdl.so.2 libpthread.so.0 \
       librt.so.1 libresolv.so.2 libstdc++.so.6 libgcc_s.so.1 "$OUT/"
echo "runtime ready: $OUT ($(./ld-linux-x86-64.so.2 --version | head -1))"
echo "leftover download in $WORK (tmpfs on SteamOS - gone on reboot)"

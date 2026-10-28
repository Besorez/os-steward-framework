#!/usr/bin/env bash
# check-glibc-needs.sh - read-only.
#
# Purpose: say whether the ELF files of a native Linux build need a newer
#          glibc / libstdc++ than this system has. A build made on a rolling
#          distribution often does, and on SteamOS that shows only as
#          "version `GLIBC_2.xx' not found" in the launch log.
# Usage:   check-glibc-needs.sh <build-dir>
# Example: check-glibc-needs.sh ~/Games/SomePort/bin
# Exit:    0 = system is new enough, 1 = a private runtime is needed, 2 = usage.
set -uo pipefail

DIR="${1:-}"
[ -d "$DIR" ] || { echo "usage: $0 <build-dir>" >&2; exit 2; }

ver_max() { sort -Vu | tail -1; }

mapfile -t ELFS < <(find "$DIR" -maxdepth 2 -type f \( -perm -u+x -o -name '*.so*' \) \
  -exec sh -c 'head -c4 "$1" | grep -q "ELF" && echo "$1"' _ {} \;)
[ "${#ELFS[@]}" -gt 0 ] || { echo "no ELF files in $DIR" >&2; exit 2; }

SYMS="$(objdump -T "${ELFS[@]}" 2>/dev/null)"
NEED_C="$(grep -oE 'GLIBC_[0-9]+\.[0-9]+' <<<"$SYMS" | sed 's/GLIBC_//' | ver_max)"
NEED_CXX="$(grep -oE 'GLIBCXX_[0-9.]+' <<<"$SYMS" | sed 's/GLIBCXX_//' | ver_max)"

HAVE_C="$(ldd --version | head -1 | grep -oE '[0-9]+\.[0-9]+$')"
LIBSTDCXX="$(ldconfig -p 2>/dev/null | awk '/libstdc\+\+\.so\.6 .*x86-64/ {print $NF; exit}')"
HAVE_CXX="$(strings "${LIBSTDCXX:-/usr/lib/libstdc++.so.6}" 2>/dev/null | grep -oE '^GLIBCXX_[0-9.]+$' | sed 's/GLIBCXX_//' | ver_max)"

echo "glibc     needed ${NEED_C:-none}   system ${HAVE_C:-?}"
echo "libstdc++ needed ${NEED_CXX:-none}   system ${HAVE_CXX:-?}"

newer() { [ -n "$1" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -1)" != "$2" ]; }
if newer "$NEED_C" "$HAVE_C" || newer "$NEED_CXX" "$HAVE_CXX"; then
  echo "verdict: needs a private runtime (build-private-glibc.sh)"
  exit 1
fi
echo "verdict: runs on the system libraries"

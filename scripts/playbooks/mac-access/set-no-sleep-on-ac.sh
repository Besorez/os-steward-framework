#!/bin/bash
# SYNOPSIS
#   Keep a Mac laptop reachable while it is on the charger: no system sleep on AC, wake for
#   network access, TCP keepalive. The lid still matters: closed without an external display
#   (clamshell) the Mac sleeps anyway.
# USAGE
#   sudo bash set-no-sleep-on-ac.sh
# ROLLBACK
#   sudo pmset -c sleep <previous value printed below>   (macOS default on AC is 1)
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "run with sudo" >&2; exit 1; }
echo "before (AC): $(pmset -g custom | awk '/AC Power/{f=1} f && /^ *(sleep|womp|tcpkeepalive) /{printf "%s=%s ", $1, $2}')"
pmset -c sleep 0 womp 1 tcpkeepalive 1
echo "after  (AC): $(pmset -g custom | awk '/AC Power/{f=1} f && /^ *(sleep|womp|tcpkeepalive) /{printf "%s=%s ", $1, $2}')"

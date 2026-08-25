#!/usr/bin/env sh
# Play a WAV through whichever sound server is running, then discard it.
#   play.sh <file.wav>
[ -n "$1" ] || exit 1
trap 'rm -f "$1"' EXIT

if command -v pw-play >/dev/null 2>&1; then
  pw-play --volume=1.0 "$1"
elif command -v paplay >/dev/null 2>&1; then
  paplay "$1"
elif command -v aplay >/dev/null 2>&1; then
  aplay -q "$1"
fi

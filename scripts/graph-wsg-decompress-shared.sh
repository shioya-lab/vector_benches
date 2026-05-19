#!/usr/bin/env bash
set -euo pipefail

# Usage: graph-wsg-decompress-shared.sh <input.bz2> <output>
in_bz2="${1:?expected input .bz2 path}"
out="${2:?expected output path}"

mkdir -p "$(dirname "$out")"
lock="${out}.lock"

if [[ -s "$out" ]]; then
  exit 0
fi

# Serialize decompression across parallel jobs.
flock "$lock" bash -lc '
  set -euo pipefail
  in_bz2="$1"
  out="$2"
  if [[ -s "$out" ]]; then exit 0; fi
  tmp="$(mktemp "${out}.tmp.XXXXXX")"
  cleanup() { rm -f "$tmp"; }
  trap cleanup EXIT
  bunzip2 -kc "$in_bz2" > "$tmp"
  test -s "$tmp"
  mv -f "$tmp" "$out"
  trap - EXIT
' _ "$in_bz2" "$out"


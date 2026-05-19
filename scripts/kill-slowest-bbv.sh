#!/usr/bin/env bash
# Kill the N slowest-progress bbv-stage jobs to relieve memory pressure.
# Usage: ./scripts/kill-slowest-bbv.sh [N]   (default N=2)
#
# Picks among containers still in BBV stage (no bbv.0.bb.gz yet),
# orders by reported "Processed X / Y nodes = %" in their qemu.log,
# docker stops the bottom N, then rm -rf their partial dirs.
# Prints the list of killed targets so the caller can record for re-run.

set -euo pipefail
N="${1:-2}"
REPO=/home/kimura/work/sniper/vector_benches
cd "$REPO"

# Dynamic discovery: any non-dataset-cache subdir of graph-wsg-out (so Step 3c / future jobs included)
DIRS=$(ls -d graph-wsg-out/*/ 2>/dev/null | grep -v 'dataset-cache' | sed 's|/$||')

# Collect (pct, dir) only for jobs still running bbv (no .gz)
tmp=$(mktemp)
for d in $DIRS; do
  [ -d "$d" ] || continue
  [ -f "$d/bbv.0.bb.gz" ] && continue  # bbv done — skip
  log=$(ls $d/*.qemu.log 2>/dev/null | head -1)
  [ -z "$log" ] && continue
  pct=$(grep -oE "= [0-9]+\.[0-9]+%" "$log" 2>/dev/null | tail -1 | tr -d '= %')
  # default to 999 if no pct (don't kill marker-detected jobs like sssp_road tail)
  pct="${pct:-999}"
  printf "%s %s\n" "$pct" "$d" >>"$tmp"
done

slowest=$(sort -g "$tmp" | head -n "$N")
rm -f "$tmp"

if [ -z "$slowest" ]; then
  echo "no killable bbv-stage jobs found" >&2
  exit 1
fi

echo "=== will kill (slowest $N) ==="
echo "$slowest"
echo

killed_targets=""
while read -r pct d; do
  name=$(basename "$d")
  # Match container by workload path in cmdline of the qemu pid
  # First, find the qemu-riscv64 PID whose cmdline contains the dataset for this dir
  case "$name" in
    bfs_*|cc_*|pr_*) prog=$(echo "$name" | cut -d_ -f1); g=$(echo "$name" | cut -d_ -f2); suffix=sg;;
    sssp_*)          prog=sssp;                       g=$(echo "$name" | cut -d_ -f2); suffix=wsg;;
  esac
  workload_basename="$g.$suffix"
  # Find host PID of qemu-riscv64 (args must START with qemu-riscv64, not make/docker wrappers)
  pid=$(ps -eo pid,args | awk -v wl="$workload_basename" -v p="$prog.riscv_rvv10.x" '$2 == "qemu-riscv64" && $0 ~ wl && $0 ~ p {print $1; exit}')
  if [ -z "$pid" ]; then
    echo "[$name] could not find qemu pid; skipping"
    continue
  fi
  # Prefer mountinfo (works for processes inside docker namespaces)
  cid=$(grep -oE 'docker/containers/[0-9a-f]{64}' /proc/$pid/mountinfo 2>/dev/null | head -1 | awk -F/ '{print $3}')
  [ -z "$cid" ] && cid=$(cat /proc/$pid/cgroup 2>/dev/null | grep -oE '[0-9a-f]{64}' | head -1)
  cname=$(docker inspect -f '{{.Name}}' "$cid" 2>/dev/null | sed 's|^/||')
  if [ -z "$cname" ]; then
    echo "[$name] could not resolve container; killing pid $pid directly"
    kill -KILL "$pid" || true
  else
    echo "[$name] docker stop $cname ($pct%)"
    docker stop -t 5 "$cname" >/dev/null || true
    sleep 2  # let qemu release file handles before NFS-rename hazard
  fi
  rm -rf "$d"
  killed_targets="$killed_targets $name"
done <<<"$slowest"

echo
echo "=== killed targets (for later re-run) ===$killed_targets"
free -h | head -2

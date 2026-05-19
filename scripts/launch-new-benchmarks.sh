#!/usr/bin/env bash
# Launch postponed bc/ccsv/prspmv/tc benchmarks at low parallelism.
# Designed to be triggered when memory utilization drops below 20%.
#
# Output: graph-wsg-out/_bbv-new-benchmarks.log (tee'd)
# Logs naming consistent with existing _bbv-gap-parallel-resume.log

set -euo pipefail
REPO=/home/kimura/work/sniper/vector_benches
cd "$REPO"

JOBS=4
DATASETS_SG=(kronU roadU twitterU urandU webU)
NEW_PROGS=(bc ccsv prspmv tc)

# Build target list: 4 progs × 5 datasets = 20 _sg targets
targets=()
for p in "${NEW_PROGS[@]}"; do
  for g in "${DATASETS_SG[@]}"; do
    targets+=("graph_wsg_bbv_${p}_${g}_sg")
  done
done

echo "=== launch-new-benchmarks: $(date -Is) ==="
echo "Parallelism: -j${JOBS}"
echo "Total targets: ${#targets[@]}"
echo "Programs: ${NEW_PROGS[*]}"
echo "Datasets: ${DATASETS_SG[*]}"

nohup bash -c "
  echo '=== new-benchmarks kicked off at \$(date -Is) ==='
  make -j${JOBS} -k ${targets[*]}
  status=\$?
  echo '=== new-benchmarks finished at \$(date -Is) exit='\$status' ==='
" 2>&1 | tee -a graph-wsg-out/_bbv-new-benchmarks.log

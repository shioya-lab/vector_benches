#!/usr/bin/env bash
# Smoke-test graph-v-rvv10-wsg ported benchmarks under qemu-riscv64 (user-mode).
# Usage: qemu-smoke-graph-wsg.sh <wsg-dir-abs> <graph-path-rel-to-wsg> <bench> [<bench> ...]
#   If GRAPH_WSG_SMOKE_GRAPHS is set, the 2nd argv is ignored and the script runs
#   all benches for each graph in that whitespace-separated list.
# Optional env:
#   QEMU, QEMU_CPU, QEMU_LD_PREFIX (for dynamically linked Linux guests; static linux build usually ignores)
#   GRAPH_WSG_QEMU_MAKEFLAGS — inner make flags. Default from top Makefile uses CUSTOM_CONF=./configs/RISCV-linux.mk
#     because qemu-riscv64 (user-mode) + riscv64-unknown-elf bare-metal ELF often cannot open host files
#     (ifstream fails) even when the path exists — that is not a Docker bind-mount problem.
#   GRAPH_WSG_QEMU_EXTRA_CXX_FLAGS — passed through to graph-v-rvv10-wsg as EXTRA_CXX_FLAGS (appended to CXX_FLAGS).
#   GRAPH_WSG_SMOKE_VERBOSE — default 1: pass VERBOSE=on so -DQUIET is off (more graph Print() output).
#   GRAPH_WSG_SMOKE_SHELL_TRACE — set to 1 for `set -x` in this script.
#   GRAPH_WSG_SMOKE_REBUILD — set to 1 to force rebuild (-B) of requested targets.
#   GRAPH_WSG_SMOKE_GRAPHS — optional whitespace-separated graph paths (relative to wsg dir
#     or absolute). When set, run all benches for each graph.
set -euo pipefail

if [[ "${GRAPH_WSG_SMOKE_SHELL_TRACE:-0}" == "1" ]]; then
	set -x
fi

if [[ "$#" -lt 3 ]]; then
	echo "usage: $0 <wsg-dir-abs> <graph-rel-to-wsg> <bench> [<bench> ...]" >&2
	exit 2
fi

WSG_DIR="$1"
GRAPH="$2"
shift 2
BENCHES=( "$@" )

cd "$WSG_DIR"

# Use an absolute graph path: qemu user-mode keeps host cwd, but relative paths
# break easily if cwd differs; missing files under graphs/ also fail clearer here.
graph_abs() {
	local g="$1"
	if [[ "$g" == /* ]]; then
		printf '%s\n' "$g"
	else
		printf '%s\n' "$(pwd)/$g"
	fi
}
resolve_graph_or_die() {
	local g="$1"
	local abs
	abs="$(graph_abs "$g")"
	if [[ ! -f "$abs" ]]; then
		echo "ERROR: graph file not found: $abs" >&2
		echo "       (from GRAPH=$g under $WSG_DIR)" >&2
		echo "       Install or generate inputs under graphs/." >&2
		if [[ -d "$(dirname "$abs")" ]]; then
			ls -la "$(dirname "$abs")" >&2 || true
		fi
		exit 1
	fi
	printf '%s\n' "$abs"
}

graphs_abs=()
if [[ -n "${GRAPH_WSG_SMOKE_GRAPHS:-}" ]]; then
	# shellcheck disable=SC2206
	graph_list=( ${GRAPH_WSG_SMOKE_GRAPHS} )
	for g in "${graph_list[@]}"; do
		graphs_abs+=( "$(resolve_graph_or_die "$g")" )
	done
else
	graphs_abs+=( "$(resolve_graph_or_die "$GRAPH")" )
fi

: "${QEMU:=qemu-riscv64}"
: "${QEMU_CPU:=rv64,zba=true,zbb=true,v=true,vlen=1024,vext_spec=v1.0}"
export QEMU_CPU

targets=()
for b in "${BENCHES[@]}"; do
	targets+=( "${b}.riscv_rvv10.x" )
done

: "${GRAPH_WSG_SMOKE_VERBOSE:=1}"
mkverbose=()
if [[ "${GRAPH_WSG_SMOKE_VERBOSE}" == "1" ]]; then
	mkverbose+=( "VERBOSE=on" )
fi

echo "== qemu-smoke-graph-wsg: build ${BENCHES[*]} (GRAPH_WSG_SMOKE_VERBOSE=${GRAPH_WSG_SMOKE_VERBOSE})"
# Some Makefile dependencies are coarse; allow forcing rebuild when iterating on code.
rebuild=()
if [[ "${GRAPH_WSG_SMOKE_REBUILD:-0}" == "1" ]]; then
	rebuild+=( "-B" )
fi
# shellcheck disable=SC2086
make "${rebuild[@]}" -f rvv10.mk -j1 "${targets[@]}" ARCH=riscv "${mkverbose[@]}" \
    EXTRA_CXX_FLAGS="${GRAPH_WSG_QEMU_EXTRA_CXX_FLAGS:-}" \
    ${GRAPH_WSG_QEMU_MAKEFLAGS:-}

for graph_abs_path in "${graphs_abs[@]}"; do
	echo "== qemu-smoke-graph-wsg: graph ${graph_abs_path}"
	for b in "${BENCHES[@]}"; do
		elf="./${b}.riscv_rvv10.x"
		echo "== qemu-smoke-graph-wsg: run ${b}"
		echo "    pwd=$(pwd)"
		ls -l "${elf}"
		if command -v file >/dev/null 2>&1; then
			file "${elf}" || true
		fi
		# time(1): wall-clock for each guest.
		if command -v stdbuf >/dev/null 2>&1; then
			time stdbuf -oL -eL "${QEMU}" "${elf}" -f "${graph_abs_path}" -v
		else
			time "${QEMU}" "${elf}" -f "${graph_abs_path}" -v
		fi
		echo "== qemu-smoke-graph-wsg: finished ${b}"
	done
done

echo "== qemu-smoke-graph-wsg: OK"

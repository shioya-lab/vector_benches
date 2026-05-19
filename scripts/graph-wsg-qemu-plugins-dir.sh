#!/usr/bin/env bash
# Print directory containing QEMU user-mode plugins (libbbv.so, libicount.so, libinsnhist.so).
# Used from Makefile docker-cmd (host and container both have $HOME mounted).
#
# Optional: GRAPH_WSG_QEMU_PLUGIN_DIR1 / GRAPH_WSG_QEMU_PLUGIN_DIR2 — checked first if set.

set -euo pipefail

check_dir() {
	local d="$1"
	# With `set -e`, returning non-zero from this helper would abort the whole script.
	# So keep it "non-fatal" when the candidate doesn't match.
	if [[ -n "$d" && -f "$d/libbbv.so" ]]; then
		printf '%s\n' "$d"
		exit 0
	fi
	return 0
}

check_dir "${GRAPH_WSG_QEMU_PLUGIN_DIR1:-}"
check_dir "${GRAPH_WSG_QEMU_PLUGIN_DIR2:-}"

q="${QEMU:-qemu-riscv64}"
qpath=""
if command -v "$q" >/dev/null 2>&1; then
	qpath="$(command -v "$q")"
	pref="$(dirname "$(dirname "$qpath")")"
	check_dir "$pref/libexec/qemu-plugins"
fi

candidates=(
	/riscv-linux/libexec/qemu-plugins
	/riscv/libexec/qemu-plugins
	/usr/local/libexec/qemu-plugins
	/usr/libexec/qemu-plugins
)

for d in "${candidates[@]}"; do
	check_dir "$d"
done

# Slow fallback: locate any libbbv.so under common prefixes.
while IFS= read -r f; do
	[[ -n "$f" ]] || continue
	d="$(dirname "$f")"
	printf '%s\n' "$d"
	exit 0
done < <(find /riscv /riscv-linux /opt /usr/local /usr -path '*/libexec/qemu-plugins/libbbv.so' 2>/dev/null | head -1)

echo "ERROR: libbbv.so not found (QEMU contrib plugins are often not installed with qemu-riscv64)." >&2
echo "       Qemu binary was: ${qpath:-<not in PATH>}" >&2
echo "       Fix: build QEMU from source (contrib/plugins) and point Make at the dir containing libbbv.so, e.g." >&2
echo "         make graph_wsg_bbv_bfs_roadU_sg GRAPH_WSG_QEMU_PLUGIN_DIR1=/path/to/qemu-build/contrib/plugins" >&2
echo "       (same pattern as graph-v-wsg QEMU10_PATH/.../contrib/plugins)." >&2
exit 1

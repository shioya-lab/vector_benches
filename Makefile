LLVM ?= 16
PRAVE_NEXT2_DIR ?= ../prave_next2

ifeq ($(LLVM),19)
	LLVM_DOCKER_OPT = -llvm19
	UBUNTU_VERSION  = 22.04
else ifeq ($(LLVM),18)
	LLVM_DOCKER_OPT = -llvm18
	UBUNTU_VERSION  = 22.04
else
	LLVM_DOCKER_OPT = -llvm16
	UBUNTU_VERSION  = 22.04
endif

DOCKER_IMAGE ?= msyksphinz/ubuntu:$(UBUNTU_VERSION)-work-sniper-$(USER)$(LLVM_DOCKER_OPT)

# Build args (match prave_next2's Docker build convention)
DOCKER_BUILD_OPT += --build-arg USER_NAME=$(USER)
DOCKER_BUILD_OPT += --build-arg USER_ID=$(shell id -u)
DOCKER_BUILD_OPT += --build-arg GROUP_ID=$(shell id -g)

# Reconstruct the timezone for tzdata (same approach as prave_next2)
TZFULL=$(subst /, ,$(shell readlink /etc/localtime))
TZ=$(word $(shell expr $(words $(TZFULL)) - 1 ),$(TZFULL))/$(word $(words $(TZFULL)),$(TZFULL))

MEM_LIMIT = $(shell awk '/MemTotal/ {printf "%.0fm", $$2 / 1024 / 2}' /proc/meminfo)

# RISCV for rivec Makefiles: ${RISCV}/bin/clang must be a RISC-V *cross* clang. Upstream uses /riscv/bin/clang
# without --target=, which selects the host triple in LLVM builds — use a small shim (scripts/rivec-riscv-shim).
RIVEC_TOOLCHAIN_SHIM := $(abspath scripts/rivec-riscv-shim)
RIVEC_RISCV ?= $(RIVEC_TOOLCHAIN_SHIM)
RIVEC_LLVM ?= /riscv
RIVEC_SYSROOT ?= /riscv/riscv64-unknown-elf
RIVEC_GCC_TOOLCHAIN ?= /riscv

GRAPH_WSG_DIR ?= graph-v-rvv10-wsg

.PHONY: help docker-build docker-shell docker-cmd sift qemu-sift qemu-smoke-graph-wsg qemu-check-graph-wsg build-all build-rivec build-graph-wsg clean-graph-wsg sift-all qemu-sift-all clean clean-rivec \
	graph-wsg-bbv-gap graph-wsg-bbv-gap-parallel graph-wsg-sift-gap graph-wsg-probe-qemu-plugins \
	graph-wsg-qemu-bbv-gap-parallel \
	$(foreach g,$(GRAPH_WSG_DATASETS_SG),graph-wsg-qemu-bbv-one-$(g)_sg) \
	$(foreach g,$(GRAPH_WSG_DATASETS_WSG),graph-wsg-qemu-bbv-one-$(g)_wsg) \
	graph-wsg-sift-gap-parallel \
	build-hpcg clean-hpcg hpcg-run-qemu-bbv hpcg-run-qemu-insnhist qemu-smoke-hpcg hpcg-bbv-all hpcg-bbv-parallel \
	hpcg-run-qemu-sift hpcg-sift-all hpcg-sift-parallel \
	$(foreach s,$(HPCG_SIZES),hpcg_bbv_$(s))

help:
	@echo "vector_benches helper targets"
	@echo ""
	@echo "Docker image can be built from this repo (Dockerfile* are copied from prave_next2)."
	@echo ""
	@echo "Targets:"
	@echo "  docker-build         Build Docker image (this repo)"
	@echo "  docker-shell         Open a shell in the Docker environment"
	@echo "  docker-cmd CMD=...   Run an arbitrary command in Docker"
	@echo "  sift BENCH=...       Generate .sift via Spike in Docker"
	@echo "  qemu-sift BENCH=...  Generate .sift via QEMU user-mode plugin in Docker"
	@echo "  build-all            Compile microbenchmarks (runspike.mk) + rivec1.0 APPLICATION_DIRS (vector) (in Docker)"
	@echo "  build-rivec          Compile only rivec1.0 benchmarks listed in rivec1.0/Makefile APPLICATION_DIRS (in Docker)"
	@echo "  build-graph-wsg      Compile graph-v-rvv10-wsg RVV binaries (rvv10.mk BENCH list; in Docker)"
	@echo "  clean-graph-wsg      Remove graph-v-rvv10-wsg objects/ELFs and rvv10 spike logs (in Docker)"
	@echo "  qemu-smoke-graph-wsg  In Docker: build ported graph bins (bc,cc_sv,pr_spmv,tc), run each under qemu-riscv64 on a small graph"
	@echo "  qemu-check-graph-wsg  In Docker: full check (ported bins × GRAPH_WSG_CHECK_GRAPHS) under qemu-riscv64 (PASS required)"
	@echo "  graph-wsg-bbv-gap     BBV+icount+SimPoint+insnhist (docker); needs QEMU contrib plugins (libbbv.so)"
	@echo "  graph-wsg-qemu-bbv-gap-parallel  BBV for all GAP graphs in parallel (outer=GRAPH_WSG_PARALLEL_JOBS=nproc, inner bfs/cc/pr=GRAPH_WSG_STAGE_QEMU_JOBS=3)"
	@echo "  hpcg_sift_<size>      HPCG SIFT for one size (needs hpcg_bbv_<size> done first; Sniper libqemu-frontend.so required)"
	@echo "  hpcg-sift-all          HPCG SIFT for every HPCG_SIZES entry (serial)"
	@echo "  hpcg-sift-parallel     HPCG SIFT for every HPCG_SIZES entry (parallel via -j$(GRAPH_WSG_PARALLEL_JOBS))"
	@echo "  graph-wsg-sift-gap    SIFT pipeline (docker); needs Sniper libqemu-frontend.so"
	@echo "  graph-wsg-sift-gap-parallel      SIFT for all GAP graphs in parallel (GRAPH_WSG_PARALLEL_JOBS=nproc)"
	@echo "  graph-wsg-probe-qemu-plugins  Print plugin dir inside Docker (or error if missing)"
	@echo "  sift-all             Spike SIFT only for dirs that include scripts/runspike.mk (upstream rivec apps usually do not)"
	@echo "  qemu-sift-all        QEMU SIFT only for dirs that include scripts/runqemu.mk"
	@echo "  clean                Clean microbenchmark runspike dirs + rivec1.0 top-level clean (in Docker)"
	@echo "  clean-rivec          Run make -C rivec1.0 clean (in Docker)"
	@echo ""
	@echo "Vars:"
	@echo "  LLVM=16|18|19            (default: 16)"
	@echo "  PRAVE_NEXT2_DIR=...      (default: ../prave_next2)"
	@echo "  BENCH=...                (default: microbenchmarks/rvv_saxpy)"
	@echo "  VLEN=...                 (default: 256)"
	@echo "  QEMU=...                 (default: qemu-riscv64)  (for qemu-sift / qemu-smoke-graph-wsg)"
	@echo "  QEMU_LD_PREFIX=...       (optional, for dynamic linux binaries under qemu-user)"
	@echo "  GRAPH_WSG_QEMU_PORTED=...  (default: bc cc_sv pr_spmv tc)  for qemu-smoke-graph-wsg"
	@echo "  GRAPH_WSG_QEMU_INPUT=...   (default: graphs/rmat/rmat_10_15.el)  path relative to graph-v-rvv10-wsg"
	@echo "  GRAPH_WSG_QEMU_MAKEFLAGS=...  inner make flags (default: CUSTOM_CONF=./configs/RISCV-linux.mk for qemu-user; empty = bare-metal /riscv)"
	@echo "  GRAPH_WSG_SMOKE_VERBOSE=0|1   (default: 1)  pass VERBOSE=on to graph build for more stdout"
	@echo "  GRAPH_WSG_SMOKE_SHELL_TRACE=1  bash -x inside qemu-smoke-graph-wsg.sh"
	@echo "  GRAPH_WSG_CHECK_GRAPHS=...     (default: graphs/rmat/rmat_10_15.el graphs/rmat/rmat_15_20.el)  for qemu-check-graph-wsg"
	@echo "  GRAPH_WSG_QEMU_PLUGIN_DIR1=...  directory containing libbbv.so (BBV path); many images omit contrib plugins — set explicitly if probe fails"
	@echo "  GRAPH_WSG_PARALLEL_JOBS=...    outer parallelism for graph-wsg-qemu-bbv-gap-parallel (default: nproc=$(shell nproc))"
	@echo "  GRAPH_WSG_STAGE_QEMU_JOBS=...  inner parallelism (bfs/cc/pr per SG graph) (default: 3)"
	@echo "  RIVEC_RISCV=...          (default: scripts/rivec-riscv-shim)  RIVEC_LLVM SYSROOT GCC_TOOLCHAIN"

docker-build:
ifeq ($(LLVM),19)
	docker build --build-arg TZ_ARG=$(TZ) $(DOCKER_BUILD_OPT) -f Dockerfile19 -t $(DOCKER_IMAGE) .
else ifeq ($(LLVM),18)
	docker build --build-arg TZ_ARG=$(TZ) $(DOCKER_BUILD_OPT) -f Dockerfile18 -t $(DOCKER_IMAGE) .
else
	docker build --build-arg TZ_ARG=$(TZ) $(DOCKER_BUILD_OPT) -f Dockerfile -t $(DOCKER_IMAGE) .
endif

docker-shell:
	docker run --cap-add=SYS_PTRACE --security-opt="seccomp=unconfined" \
		--rm -it --memory=$(MEM_LIMIT) \
		-v "${HOME}:${HOME}" -v "/tmp:/tmp" \
		--user $(shell id -u):$(shell id -g) -w "${PWD}" \
		$(DOCKER_IMAGE) bash

docker-cmd:
ifeq ($(strip $(CMD)),)
	$(error "ERROR: set CMD='...'")
endif
	docker run --cap-add=SYS_PTRACE --security-opt="seccomp=unconfined" \
		--rm -t --memory=$(MEM_LIMIT) \
		-v "${HOME}:${HOME}" -v "/tmp:/tmp" \
		--user $(shell id -u):$(shell id -g) -w "${PWD}" \
		-e RUN_CMD='$(CMD)' \
		$(DOCKER_IMAGE) bash -lc 'eval "$$RUN_CMD"'

# Generate a .sift file by running Spike with --sift (see scripts/runspike.mk)
BENCH ?= microbenchmarks/rvv_saxpy
VLEN ?= 256
TARGET_OS ?= elf
# Building `rivec1.0/_fftw3` can take a long time because it bootstraps
# and builds FFTW from source. Keep it opt-in for `build-all`/`sift-all`.
INCLUDE_FFTW3 ?= 0
sift:
	@test -d "$(BENCH)" || (echo "ERROR: BENCH not found: $(BENCH)" && exit 2)
	@test -d "$(PRAVE_NEXT2_DIR)/sniper" || (echo "ERROR: expected Sniper under PRAVE_NEXT2_DIR/sniper (got: $(PRAVE_NEXT2_DIR)/sniper)" && exit 2)
	@test -d "$(PRAVE_NEXT2_DIR)/riscv-isa-sim" || (echo "ERROR: expected riscv-isa-sim under PRAVE_NEXT2_DIR/riscv-isa-sim (got: $(PRAVE_NEXT2_DIR)/riscv-isa-sim)" && exit 2)
	$(MAKE) docker-cmd CMD="make -C \"$(BENCH)\" runspike-v VLEN=$(VLEN) SNIPER_ROOT=\"$(realpath $(PRAVE_NEXT2_DIR)/sniper)\" SPIKE_ROOT=\"$(realpath $(PRAVE_NEXT2_DIR)/riscv-isa-sim)\""

QEMU ?= qemu-riscv64
QEMU_LD_PREFIX ?=
# qemu-smoke-graph-wsg: ported kernels + small unweighted graph (same style as sim_run.mk + rvv10.mk QEMU_ENV).
GRAPH_WSG_QEMU_PORTED ?= bc cc_sv pr_spmv tc
GRAPH_WSG_QEMU_INPUT ?= graphs/rmat/rmat_10_15.el
GRAPH_WSG_QEMU_CPU ?= rv64,zba=true,zbb=true,v=true,vlen=1024,vext_spec=v1.0
# qemu-user expects a Linux/RISC-V binary: bare-metal riscv64-unknown-elf often fails fopen/ifstream on host paths even when test -f passes.
GRAPH_WSG_QEMU_MAKEFLAGS ?= CUSTOM_CONF=./configs/RISCV-linux.mk
# Extra flags appended to graph-v-rvv10-wsg's CXX_FLAGS (via EXTRA_CXX_FLAGS variable in that Makefile).
GRAPH_WSG_QEMU_EXTRA_CXX_FLAGS ?=
# 1 = inner make with VERBOSE=on (no -DQUIET; more graph Print output). 0 = quiet build.
GRAPH_WSG_SMOKE_VERBOSE ?= 1
# 1 = bash set -x in qemu-smoke script (debug pipeline).
GRAPH_WSG_SMOKE_SHELL_TRACE ?= 0
# 1 = force rebuild (-B) of graph targets inside qemu-smoke script.
GRAPH_WSG_SMOKE_REBUILD ?= 0
# Full check graphs list (whitespace-separated, paths relative to graph-v-rvv10-wsg unless absolute).
GRAPH_WSG_CHECK_GRAPHS ?= graphs/rmat/rmat_10_15.el graphs/rmat/rmat_15_20.el

# ===== graph-v-wsg style pipelines (BBV / SimPoint / SIFT) =====
# These targets mirror /home/kimura/work/sniper/graph-v-wsg/Makefile but run via this repo's docker-cmd.
#
# Notes:
# - BBV/ICOUNT/INSNHIST use QEMU plugins (libbbv.so, libicount.so, libinsnhist.so).
#   In our Dockerfile we install QEMU under /riscv (and later /riscv-linux for toolchain),
#   so default plugin dir is under /riscv-linux/libexec/qemu-plugins or /riscv/libexec/qemu-plugins.
# - SimPoint binary is built into the Docker image at /usr/local/bin/simpoint
#   (Dockerfile builds s117/SimPoint). Override SIMPOINT_BIN=... to point at a
#   host install instead (host $HOME is mounted into the container).
# - SIFT uses Sniper QEMU frontend plugin; requires a Sniper tree built with BUILD_QEMU=1.

# Program directory containing graph-v-rvv10-wsg binaries.
GRAPH_WSG_BIN_DIR ?= $(abspath $(GRAPH_WSG_DIR))
# Where “production” graph datasets live (host path, mounted into Docker).
GRAPH_WSG_DATASET_DIR ?= /home/kimura/work/gap/gap_riscv/benchmark/graphs

# QEMU plugin locations (override if your image installs elsewhere).
GRAPH_WSG_QEMU_PLUGIN_DIR1 ?= /riscv-linux/libexec/qemu-plugins
GRAPH_WSG_QEMU_PLUGIN_DIR2 ?= /riscv/libexec/qemu-plugins
# Container-side script: finds directory containing libbbv.so (BBV/ICOUNT/insnhist).
GRAPH_WSG_QEMU_PLUGINS_SCRIPT ?= $(abspath scripts/graph-wsg-qemu-plugins-dir.sh)

# QEMU plugin shared objects.
GRAPH_WSG_QEMU_BBV_SO      ?= $(GRAPH_WSG_QEMU_PLUGIN_DIR1)/libbbv.so
GRAPH_WSG_QEMU_ICOUNT_SO   ?= $(GRAPH_WSG_QEMU_PLUGIN_DIR1)/libicount.so
GRAPH_WSG_QEMU_INSNHIST_SO ?= $(GRAPH_WSG_QEMU_PLUGIN_DIR1)/libinsnhist.so

# SimPoint. Built into the Docker image at /usr/local/bin/simpoint
# (see Dockerfile: s117/SimPoint fork). Override SIMPOINT_BIN=... to use a
# host-side install (e.g. $HOME/SimPoint/bin/simpoint) — host $HOME is mounted
# into the container by docker-cmd.
SIMPOINT_BIN ?= /usr/local/bin/simpoint
SIMPOINT_K ?= 1
SIMPOINT_OPTIONS ?= -inputVectorsGzipped -k $(SIMPOINT_K)

# Interval used by QEMU plugins (also used to convert ROI instruction counts to “lines” in bbv.*.bb).
GRAPH_WSG_INTERVAL ?= 500000

# SIFT recording layout (instructions, not interval count):
#   SIFT = [WARMUP_PRE] [INTERVAL: representative] [POST_PAD: safety after representative]
#   fast_forward starts WARMUP_PRE before the SimPoint-chosen representative interval.
# Defaults are chosen so the legacy formula (2 lead-in intervals, no tail) is reproduced
# for GRAPH_WSG_INTERVAL = 500000: WARMUP_PRE = 1000000 (= 2 × interval), POST_PAD = 0,
# giving the original SIFT length of 3 × interval = 1.5M.
# When increasing the interval, prefer overriding all three on the command line, e.g.:
#   make ... GRAPH_WSG_INTERVAL=2000000 GRAPH_WSG_WARMUP_PRE=500000 GRAPH_WSG_POST_PAD=1000000
GRAPH_WSG_WARMUP_PRE ?= 1000000
GRAPH_WSG_POST_PAD   ?= 0

# Extra args appended to the graph kernel invocation (bbv / insnhist / sift).
# e.g. KERNEL_ARGS="-i 5" to cap bc source iters / pr_spmv PR iters on huge graphs.
# Must be identical across bbv/insnhist/sift of one bench so instruction counts line up.
# (Command-line overrides auto-propagate to sub-makes via MAKEFLAGS.)
KERNEL_ARGS ?=

# Output root for pipelines (inside repo, so it’s preserved).
GRAPH_WSG_OUT ?= $(abspath graph-wsg-out)
# Shared decompression cache for huge graph datasets.
# Prevents duplicating the same decompressed file across parallel jobs.
GRAPH_WSG_DATASET_CACHE ?= $(GRAPH_WSG_OUT)/dataset-cache
GRAPH_WSG_DECOMPRESS_SHARED ?= $(abspath scripts/graph-wsg-decompress-shared.sh)

# Staged execution knobs (decompress -> qemu jobs -> next decompress ...).
GRAPH_WSG_STAGE_QEMU_JOBS ?= 3
# Outer parallelism: number of graphs to process simultaneously in graph-wsg-qemu-bbv-gap-parallel.
GRAPH_WSG_PARALLEL_JOBS ?= $(shell nproc)

# Sniper QEMU frontend plugin (for SIFT).
SNIPER_ROOT ?= $(realpath $(PRAVE_NEXT2_DIR)/sniper)
GRAPH_WSG_QEMU_SIFT_PLUGIN ?= $(SNIPER_ROOT)/frontend/qemu-frontend/libqemu-frontend.so

# Extra environment for QEMU runs (matches graph-v-wsg; tweak as needed).
GRAPH_WSG_QEMU_ENV ?= QEMU_CPU=rv64,zba=true,zbb=true,v=true,vlen=1024,vext_spec=v1.0,rvv_ta_all_1s=true,rvv_ma_all_1s=true

# docker-cmd does RUN_CMD='$(CMD)'. The sub-make expands $(CMD) again, so shell vars like
# $plugin_dir become $p + lugin_dir (Make thinks $p is a variable). In recipes passed to
# $(MAKE) docker-cmd, use $$$$name so after the sub-make CMD expansion RUN_CMD contains $name.

# Debug: does this Docker image have contrib plugins? (prints path or fails with message)
graph-wsg-probe-qemu-plugins:
	$(MAKE) docker-cmd CMD='export GRAPH_WSG_QEMU_PLUGIN_DIR1="$(GRAPH_WSG_QEMU_PLUGIN_DIR1)"; export GRAPH_WSG_QEMU_PLUGIN_DIR2="$(GRAPH_WSG_QEMU_PLUGIN_DIR2)"; bash "$(GRAPH_WSG_QEMU_PLUGINS_SCRIPT)"'

# Internal: run qemu with BBV + ICOUNT plugins.
graph-wsg-run-qemu-bbv:
	@test -d "$(GRAPH_WSG_BIN_DIR)" || (echo "ERROR: GRAPH_WSG_BIN_DIR not found: $(GRAPH_WSG_BIN_DIR)" && exit 2)
	@test -f "$(GRAPH_WSG_BIN_DIR)/$(PROGRAM)" || (echo "ERROR: program not found: $(GRAPH_WSG_BIN_DIR)/$(PROGRAM)" && exit 2)
	$(MAKE) docker-cmd CMD='set -euo pipefail; \
		export GRAPH_WSG_QEMU_PLUGIN_DIR1="$(GRAPH_WSG_QEMU_PLUGIN_DIR1)"; export GRAPH_WSG_QEMU_PLUGIN_DIR2="$(GRAPH_WSG_QEMU_PLUGIN_DIR2)"; \
		plugin_dir=$$$$(bash "$(GRAPH_WSG_QEMU_PLUGINS_SCRIPT)"); \
		test -f "$(SIMPOINT_BIN)" || echo "WARN: SIMPOINT_BIN not found (later simpoint step will fail): $(SIMPOINT_BIN)" >&2; \
		mkdir -p "$(DIR)"; \
		mkdir -p "$(GRAPH_WSG_DATASET_CACHE)"; \
		workload="$(WORKLOAD)"; \
		# If workload is a dangling symlink, fall back to symlink-target .bz2. \
		if [ ! -f "$$$$workload" ]; then \
			bz2="$$$$workload.bz2"; \
			if [ ! -f "$$$$bz2" ] && [ -L "$$$$workload" ]; then \
				tgt=$$$$(readlink -f "$$$$workload" 2>/dev/null || true); \
				if [ -n "$$$$tgt" ] && [ -f "$$$$tgt.bz2" ]; then bz2="$$$$tgt.bz2"; fi; \
			fi; \
		fi; \
		if [ ! -f "$$$$workload" ] && [ -f "$$$$bz2" ]; then \
			base=$$$$(basename "$$$$workload"); \
			out="$(GRAPH_WSG_DATASET_CACHE)/$$$$base"; \
			if [ ! -s "$$$$out" ]; then \
				echo "== graph-wsg: decompress (shared) $$$$bz2 -> $$$$out"; \
				bash "$(GRAPH_WSG_DECOMPRESS_SHARED)" "$$$$bz2" "$$$$out"; \
			fi; \
			workload="$$$$out"; \
		fi; \
		test -f "$$$$workload" || (echo "ERROR: workload not found: $(WORKLOAD) (or $(WORKLOAD).bz2)" >&2 && exit 2); \
		echo "== graph-wsg: qemu bbv icount: $(PROGRAM) workload=$(WORKLOAD) out=$(DIR)"; \
		$(GRAPH_WSG_QEMU_ENV) "$(QEMU)" \
			-plugin "$$$$plugin_dir/libbbv.so,interval=$(GRAPH_WSG_INTERVAL),outfile=$(DIR)/bbv" \
			-plugin "$$$$plugin_dir/libicount.so,interval=$(GRAPH_WSG_INTERVAL)" \
			"$(GRAPH_WSG_BIN_DIR)/$(PROGRAM)" -f "$$$$workload" -v $(KERNEL_ARGS) > "$(LOGFILE)" 2>&1'

# Internal: run SimPoint on ROI BBV.
graph-wsg-run-simpoint:
	$(MAKE) docker-cmd CMD='set -euo pipefail; \
		test -x "$(SIMPOINT_BIN)" || (echo "ERROR: SIMPOINT_BIN not executable: $(SIMPOINT_BIN)" >&2; exit 2); \
		cd "$(DIR)"; \
		echo "== graph-wsg: simpoint: $$$$PWD"; \
		"$(SIMPOINT_BIN)" $(SIMPOINT_OPTIONS) -loadFVFile bbv.0.roi.bb.gz -saveSimpoints results.simpts -saveSimpointWeights results.weights > simpoint.rpt 2>&1'

# Internal: run instruction histogram plugin for the selected simpoints.
graph-wsg-run-qemu-insnhist:
	$(MAKE) docker-cmd CMD='set -euo pipefail; \
		export GRAPH_WSG_QEMU_PLUGIN_DIR1="$(GRAPH_WSG_QEMU_PLUGIN_DIR1)"; export GRAPH_WSG_QEMU_PLUGIN_DIR2="$(GRAPH_WSG_QEMU_PLUGIN_DIR2)"; \
		plugin_dir=$$$$(bash "$(GRAPH_WSG_QEMU_PLUGINS_SCRIPT)"); \
		test -f "$(DIR)/results.simpts" || (echo "ERROR: missing $(DIR)/results.simpts; run simpoint first" >&2; exit 2); \
		test -f "$(DIR)/qemu.log.roi" || (echo "ERROR: missing $(DIR)/qemu.log.roi; run bbv first" >&2; exit 2); \
		base=$$$$(head -n 1 "$(DIR)/qemu.log.roi"); \
		start_points=$$$$(while read -r sp _; do echo $$$$(( $$$$base + sp )); done < "$(DIR)/results.simpts" | paste -sd/); \
		echo "== graph-wsg: insnhist start_points=$$$$start_points"; \
		mkdir -p "$(GRAPH_WSG_DATASET_CACHE)"; \
		workload="$(WORKLOAD)"; \
		if [ ! -f "$$$$workload" ]; then \
			bz2="$$$$workload.bz2"; \
			if [ ! -f "$$$$bz2" ] && [ -L "$$$$workload" ]; then \
				tgt=$$$$(readlink -f "$$$$workload" 2>/dev/null || true); \
				if [ -n "$$$$tgt" ] && [ -f "$$$$tgt.bz2" ]; then bz2="$$$$tgt.bz2"; fi; \
			fi; \
		fi; \
		if [ ! -f "$$$$workload" ] && [ -f "$$$$bz2" ]; then \
			base=$$$$(basename "$$$$workload"); \
			out="$(GRAPH_WSG_DATASET_CACHE)/$$$$base"; \
			if [ ! -s "$$$$out" ]; then \
				echo "== graph-wsg: decompress (shared) $$$$bz2 -> $$$$out"; \
				bash "$(GRAPH_WSG_DECOMPRESS_SHARED)" "$$$$bz2" "$$$$out"; \
			fi; \
			workload="$$$$out"; \
		fi; \
		test -f "$$$$workload" || (echo "ERROR: workload not found: $(WORKLOAD) (or $(WORKLOAD).bz2)" >&2 && exit 2); \
		cd "$(DIR)"; \
		$(GRAPH_WSG_QEMU_ENV) "$(QEMU)" \
			-plugin "$$$$plugin_dir/libinsnhist.so,interval=$(GRAPH_WSG_INTERVAL),start_points=$$$$start_points" \
			"$(GRAPH_WSG_BIN_DIR)/$(PROGRAM)" -f "$$$$workload" -v $(KERNEL_ARGS) > qemu.insnhist.log 2>&1'

# Internal: run SIFT generation using Sniper qemu-frontend plugin.
graph-wsg-run-qemu-sift:
	$(MAKE) docker-cmd CMD='set -euo pipefail; \
		test -f "$(GRAPH_WSG_QEMU_SIFT_PLUGIN)" || (echo "ERROR: missing Sniper QEMU frontend plugin: $(GRAPH_WSG_QEMU_SIFT_PLUGIN)" >&2; exit 2); \
		test -f "$(DIR)/qemu.log.roi" || (echo "ERROR: missing $(DIR)/qemu.log.roi; run bbv first" >&2; exit 2); \
		test -f "$(DIR)/results.simpts" || (echo "ERROR: missing $(DIR)/results.simpts; run simpoint first" >&2; exit 2); \
		fast_forward=$$$$(( ( $$$$(head -n1 "$(DIR)/qemu.log.roi") + $$$$(cut -f1 -d" " "$(DIR)/results.simpts") ) * $(GRAPH_WSG_INTERVAL) - $(GRAPH_WSG_WARMUP_PRE) )); \
		detailed=$$$$(( $(GRAPH_WSG_WARMUP_PRE) + $(GRAPH_WSG_INTERVAL) + $(GRAPH_WSG_POST_PAD) )); \
		echo "== graph-wsg: sift ff=$$$$fast_forward detailed=$$$$detailed"; \
		mkdir -p "$(DIR)"; \
		LD_LIBRARY_PATH="$(SNIPER_ROOT)/xed_kit/lib" $(GRAPH_WSG_QEMU_ENV) "$(QEMU)" \
			-plugin "$(GRAPH_WSG_QEMU_SIFT_PLUGIN),blocksize=10000000,fast_forward_target=$$$$fast_forward,detailed_target=$$$$detailed,output_file=$(DIR)/rvv-test_v1024" \
			"$(GRAPH_WSG_BIN_DIR)/$(PROGRAM)" -f "$(WORKLOAD)" -v $(KERNEL_ARGS) > "$(DIR)/$(PROGRAM).sift.log" 2>&1'

# Map target-shorthand program names back to the actual binary file names.
# Used because Makefile pattern split-on-underscore can't directly carry program names
# containing '_' (cc_sv, pr_spmv). Targets use shorthand (ccsv, prspmv) instead.
graph_wsg_prog_to_binary = $(if $(filter ccsv,$(1)),cc_sv,$(if $(filter prspmv,$(1)),pr_spmv,$(1)))

# Generic rule: graph_wsg_bbv_<prog>_<graph>_sg
graph_wsg_bbv_%_sg: WORKDIR = $(GRAPH_WSG_OUT)/$(subst _sg,,$(subst graph_wsg_bbv_,,$@))
graph_wsg_bbv_%_sg: PROGRAM = $(call graph_wsg_prog_to_binary,$(word 4,$(subst _, ,$@))).riscv_rvv10.x
graph_wsg_bbv_%_sg: GRAPH   = $(word 5,$(subst _, ,$@))
graph_wsg_bbv_%_sg: WORKLOAD = $(GRAPH_WSG_DATASET_DIR)/$(GRAPH).sg
graph_wsg_bbv_%_sg: LOGFILE = $(WORKDIR)/$(PROGRAM).$(GRAPH).qemu.log
graph_wsg_bbv_%_sg:
	@echo "==> graph-wsg BBV pipeline (sg): graph=$(GRAPH) program=$(PROGRAM)"
	$(MAKE) graph-wsg-run-qemu-bbv DIR=$(WORKDIR) WORKLOAD=$(WORKLOAD) PROGRAM=$(PROGRAM) LOGFILE=$(LOGFILE)
	awk '/Target instruction 0x00100013.*detected at instruction count: [0-9]+/ {match($$0, /instruction count: ([0-9]+)/, arr); print int(arr[1] / $(GRAPH_WSG_INTERVAL))}' $(LOGFILE) >  $(WORKDIR)/qemu.log.roi
	awk '/Target instruction 0x00200013.*detected at instruction count: [0-9]+/ {match($$0, /instruction count: ([0-9]+)/, arr); print int(arr[1] / $(GRAPH_WSG_INTERVAL))}' $(LOGFILE) >> $(WORKDIR)/qemu.log.roi
	gzip -f $(WORKDIR)/bbv.0.bb || true
	@roi_start_line=$$(head -n 1 $(WORKDIR)/qemu.log.roi); roi_end_line=$$(tail -n 1 $(WORKDIR)/qemu.log.roi); \
		gunzip -c $(WORKDIR)/bbv.0.bb.gz | head -n $$((roi_end_line + 1)) | tail -n +$$((roi_start_line + 1)) > $(WORKDIR)/bbv.0.roi.bb
	gzip -f $(WORKDIR)/bbv.0.roi.bb || true
	$(MAKE) graph-wsg-run-simpoint DIR=$(WORKDIR)
	$(MAKE) graph-wsg-run-qemu-insnhist DIR=$(WORKDIR) WORKLOAD=$(WORKLOAD) PROGRAM=$(PROGRAM)

# Generic rule: graph_wsg_bbv_<prog>_<graph>_wsg
graph_wsg_bbv_%_wsg: WORKDIR = $(GRAPH_WSG_OUT)/$(subst _wsg,,$(subst graph_wsg_bbv_,,$@))
graph_wsg_bbv_%_wsg: PROGRAM = $(call graph_wsg_prog_to_binary,$(word 4,$(subst _, ,$@))).riscv_rvv10.x
graph_wsg_bbv_%_wsg: GRAPH   = $(word 5,$(subst _, ,$@))
graph_wsg_bbv_%_wsg: WORKLOAD = $(GRAPH_WSG_DATASET_DIR)/$(GRAPH).wsg
graph_wsg_bbv_%_wsg: LOGFILE = $(WORKDIR)/$(PROGRAM).$(GRAPH).qemu.log
graph_wsg_bbv_%_wsg:
	@echo "==> graph-wsg BBV pipeline (wsg): graph=$(GRAPH) program=$(PROGRAM)"
	$(MAKE) graph-wsg-run-qemu-bbv DIR=$(WORKDIR) WORKLOAD=$(WORKLOAD) PROGRAM=$(PROGRAM) LOGFILE=$(LOGFILE)
	awk '/Target instruction 0x00100013.*detected at instruction count: [0-9]+/ {match($$0, /instruction count: ([0-9]+)/, arr); print int(arr[1] / $(GRAPH_WSG_INTERVAL))}' $(LOGFILE) >  $(WORKDIR)/qemu.log.roi
	awk '/Target instruction 0x00200013.*detected at instruction count: [0-9]+/ {match($$0, /instruction count: ([0-9]+)/, arr); print int(arr[1] / $(GRAPH_WSG_INTERVAL))}' $(LOGFILE) >> $(WORKDIR)/qemu.log.roi
	gzip -f $(WORKDIR)/bbv.0.bb || true
	@roi_start_line=$$(head -n 1 $(WORKDIR)/qemu.log.roi); roi_end_line=$$(tail -n 1 $(WORKDIR)/qemu.log.roi); \
		gunzip -c $(WORKDIR)/bbv.0.bb.gz | head -n $$((roi_end_line + 1)) | tail -n +$$((roi_start_line + 1)) > $(WORKDIR)/bbv.0.roi.bb
	gzip -f $(WORKDIR)/bbv.0.roi.bb || true
	$(MAKE) graph-wsg-run-simpoint DIR=$(WORKDIR)
	$(MAKE) graph-wsg-run-qemu-insnhist DIR=$(WORKDIR) WORKLOAD=$(WORKLOAD) PROGRAM=$(PROGRAM)

# SIFT rules mirror the BBV rules (graph_wsg_bbv_%_{sg,wsg}): split _sg / _wsg so the
# dataset extension and WORKDIR are unambiguous, and reuse graph_wsg_prog_to_binary so
# shorthand program names (ccsv -> cc_sv, prspmv -> pr_spmv) map to the real binaries.
# WORKLOAD uses the decompressed file in the shared cache (graph-wsg-run-qemu-sift has
# no decompress fallback). The Sniper SIFT plugin writes rvv-test_v1024.0.sift, so we
# add the rvv-test_v1024.sift symlink that prepare_directories.py / runeval expect.
graph_wsg_sift_%_sg: WORKDIR  = $(GRAPH_WSG_OUT)/$(subst _sg,,$(subst graph_wsg_sift_,,$@))
graph_wsg_sift_%_sg: PROGRAM  = $(call graph_wsg_prog_to_binary,$(word 4,$(subst _, ,$@))).riscv_rvv10.x
graph_wsg_sift_%_sg: GRAPH    = $(word 5,$(subst _, ,$@))
graph_wsg_sift_%_sg: WORKLOAD = $(GRAPH_WSG_DATASET_CACHE)/$(GRAPH).sg
graph_wsg_sift_%_sg:
	@echo "==> graph-wsg SIFT pipeline (sg): graph=$(GRAPH) program=$(PROGRAM)"
	$(MAKE) graph-wsg-run-qemu-sift DIR=$(WORKDIR) WORKLOAD=$(WORKLOAD) PROGRAM=$(PROGRAM)
	ln -sf rvv-test_v1024.0.sift $(WORKDIR)/rvv-test_v1024.sift

graph_wsg_sift_%_wsg: WORKDIR  = $(GRAPH_WSG_OUT)/$(subst _wsg,,$(subst graph_wsg_sift_,,$@))
graph_wsg_sift_%_wsg: PROGRAM  = $(call graph_wsg_prog_to_binary,$(word 4,$(subst _, ,$@))).riscv_rvv10.x
graph_wsg_sift_%_wsg: GRAPH    = $(word 5,$(subst _, ,$@))
graph_wsg_sift_%_wsg: WORKLOAD = $(GRAPH_WSG_DATASET_CACHE)/$(GRAPH).wsg
graph_wsg_sift_%_wsg:
	@echo "==> graph-wsg SIFT pipeline (wsg): graph=$(GRAPH) program=$(PROGRAM)"
	$(MAKE) graph-wsg-run-qemu-sift DIR=$(WORKDIR) WORKLOAD=$(WORKLOAD) PROGRAM=$(PROGRAM)
	ln -sf rvv-test_v1024.0.sift $(WORKDIR)/rvv-test_v1024.sift

# Meta targets (road/twitter/urand/web/kronU datasets).
GRAPH_WSG_DATASETS_SG  ?= kronU roadU twitterU urandU webU
GRAPH_WSG_DATASETS_WSG ?= kron road twitter urand web
graph-wsg-bbv-gap: \
  $(foreach g,$(GRAPH_WSG_DATASETS_SG),graph_wsg_bbv_bfs_$(g)_sg) \
  $(foreach g,$(GRAPH_WSG_DATASETS_SG),graph_wsg_bbv_cc_$(g)_sg) \
  $(foreach g,$(GRAPH_WSG_DATASETS_SG),graph_wsg_bbv_pr_$(g)_sg) \
  $(foreach g,$(GRAPH_WSG_DATASETS_SG),graph_wsg_bbv_bc_$(g)_sg) \
  $(foreach g,$(GRAPH_WSG_DATASETS_SG),graph_wsg_bbv_ccsv_$(g)_sg) \
  $(foreach g,$(GRAPH_WSG_DATASETS_SG),graph_wsg_bbv_prspmv_$(g)_sg) \
  $(foreach g,$(GRAPH_WSG_DATASETS_SG),graph_wsg_bbv_tc_$(g)_sg) \
  $(foreach g,$(GRAPH_WSG_DATASETS_WSG),graph_wsg_bbv_sssp_$(g)_wsg)

# Fully parallel BBV+SimPoint: all 20 jobs run concurrently.
# Parallelism = GRAPH_WSG_PARALLEL_JOBS (default: nproc).
graph-wsg-bbv-gap-parallel:
	$(MAKE) -j$(GRAPH_WSG_PARALLEL_JOBS) graph-wsg-bbv-gap

# ===== staged execution (disk-friendly) =====
.PHONY: graph-wsg-cache-% graph-wsg-qemu-bbv-graph graph-wsg-qemu-bbv-gap-staged

# Prepare shared cache for a single dataset (creates/refreshes $(GRAPH_WSG_DATASET_CACHE)/<name>.<suffix>).
# - If the raw file exists, we symlink it into the cache (no extra disk).
# - Else if a .bz2 exists (including a dangling-symlink target .bz2), we decompress once into the cache.
graph-wsg-cache-%:
	@bash -lc 'set -euo pipefail; \
		mkdir -p "$(GRAPH_WSG_DATASET_CACHE)"; \
		name="$*"; \
		case "$$name" in \
			*_sg)  graph="$${name%_sg}";  suffix="sg" ;; \
			*_wsg) graph="$${name%_wsg}"; suffix="wsg" ;; \
			*) echo "ERROR: expected suffix _sg or _wsg (got: $$name)" >&2; exit 2 ;; \
		esac; \
		workload="$(GRAPH_WSG_DATASET_DIR)/$$graph.$$suffix"; \
		out="$(GRAPH_WSG_DATASET_CACHE)/$$graph.$$suffix"; \
		if [ -s "$$out" ]; then exit 0; fi; \
		if [ -f "$$workload" ]; then \
			ln -sf "$$workload" "$$out"; \
			exit 0; \
		fi; \
		bz2="$$workload.bz2"; \
		if [ ! -f "$$bz2" ] && [ -L "$$workload" ]; then \
			tgt=$$(readlink -f "$$workload" 2>/dev/null || true); \
			if [ -n "$$tgt" ] && [ -f "$$tgt.bz2" ]; then bz2="$$tgt.bz2"; fi; \
		fi; \
		test -f "$$bz2" || (echo "ERROR: workload not found: $$workload (or $$bz2)" >&2; exit 2); \
		echo "== graph-wsg-cache: decompress $$bz2 -> $$out"; \
		bash "$(GRAPH_WSG_DECOMPRESS_SHARED)" "$$bz2" "$$out"; \
		true'

# Run only the QEMU BBV+icount step for a single graph dataset (no SimPoint/insnhist).
# Usage examples:
#   make graph-wsg-qemu-bbv-graph GRAPH=webU SUFFIX=sg
#   make graph-wsg-qemu-bbv-graph GRAPH=road  SUFFIX=wsg
graph-wsg-qemu-bbv-graph:
	@bash -lc 'set -euo pipefail; \
		test -n "$(GRAPH)" || (echo "ERROR: set GRAPH=..." >&2; exit 2); \
		test -n "$(SUFFIX)" || (echo "ERROR: set SUFFIX=sg|wsg" >&2; exit 2); \
		workload="$(GRAPH_WSG_DATASET_CACHE)/$(GRAPH).$(SUFFIX)"; \
		test -f "$$workload" || (echo "ERROR: missing cached workload: $$workload (run make graph-wsg-cache-$(GRAPH)_$(SUFFIX) first)" >&2; exit 2); \
		echo "==> graph-wsg staged QEMU-BBV: graph=$(GRAPH).$(SUFFIX)"; \
		if [ "$(SUFFIX)" = "sg" ]; then \
			$(MAKE) -j$(GRAPH_WSG_STAGE_QEMU_JOBS) \
				graph-wsg-run-qemu-bbv DIR="$(GRAPH_WSG_OUT)/bfs_$(GRAPH)" PROGRAM="bfs.riscv_rvv10.x" WORKLOAD="$$workload" LOGFILE="$(GRAPH_WSG_OUT)/bfs_$(GRAPH)/bfs.riscv_rvv10.x.$(GRAPH).qemu.log" \
				graph-wsg-run-qemu-bbv DIR="$(GRAPH_WSG_OUT)/cc_$(GRAPH)"  PROGRAM="cc.riscv_rvv10.x"  WORKLOAD="$$workload" LOGFILE="$(GRAPH_WSG_OUT)/cc_$(GRAPH)/cc.riscv_rvv10.x.$(GRAPH).qemu.log" \
				graph-wsg-run-qemu-bbv DIR="$(GRAPH_WSG_OUT)/pr_$(GRAPH)"  PROGRAM="pr.riscv_rvv10.x"  WORKLOAD="$$workload" LOGFILE="$(GRAPH_WSG_OUT)/pr_$(GRAPH)/pr.riscv_rvv10.x.$(GRAPH).qemu.log"; \
		elif [ "$(SUFFIX)" = "wsg" ]; then \
			$(MAKE) -j$(GRAPH_WSG_STAGE_QEMU_JOBS) \
				graph-wsg-run-qemu-bbv DIR="$(GRAPH_WSG_OUT)/sssp_$(GRAPH)" PROGRAM="sssp.riscv_rvv10.x" WORKLOAD="$$workload" LOGFILE="$(GRAPH_WSG_OUT)/sssp_$(GRAPH)/sssp.riscv_rvv10.x.$(GRAPH).qemu.log"; \
		else \
			echo "ERROR: unknown SUFFIX=$(SUFFIX) (expected sg|wsg)" >&2; exit 2; \
		fi; \
		true'

# Disk-friendly staged run:
# For each dataset, build the shared cache first, then run the QEMU BBV jobs for that dataset.
graph-wsg-qemu-bbv-gap-staged:
	@bash -lc 'set -euo pipefail; \
		for g in $(GRAPH_WSG_DATASETS_SG); do \
			$(MAKE) "graph-wsg-cache-$${g}_sg"; \
			$(MAKE) graph-wsg-qemu-bbv-graph GRAPH="$$g" SUFFIX=sg; \
		done; \
		for g in $(GRAPH_WSG_DATASETS_WSG); do \
			$(MAKE) "graph-wsg-cache-$${g}_wsg"; \
			$(MAKE) graph-wsg-qemu-bbv-graph GRAPH="$$g" SUFFIX=wsg; \
		done; \
		true'

# Per-graph BBV target: cache + all QEMU BBV jobs for one graph.
# % = <GRAPH>_sg (e.g. kronU_sg) or <GRAPH>_wsg (e.g. kron_wsg).
graph-wsg-qemu-bbv-one-%:
	@bash -lc 'set -euo pipefail; \
		name="$*"; \
		case "$$name" in \
			*_sg)  graph="$${name%_sg}";  suffix="sg" ;; \
			*_wsg) graph="$${name%_wsg}"; suffix="wsg" ;; \
			*) echo "ERROR: expected _sg or _wsg suffix (got: $$name)" >&2; exit 2 ;; \
		esac; \
		$(MAKE) "graph-wsg-cache-$*"; \
		$(MAKE) graph-wsg-qemu-bbv-graph GRAPH="$$graph" SUFFIX="$$suffix"'

# Fully parallel run: all graphs launched concurrently.
# Outer parallelism = GRAPH_WSG_PARALLEL_JOBS (default: nproc).
# Inner parallelism per SG graph (bfs/cc/pr) = GRAPH_WSG_STAGE_QEMU_JOBS (default: 3).
# Max simultaneous QEMU containers: 5*3 + 5*1 = 20.
graph-wsg-qemu-bbv-gap-parallel:
	$(MAKE) -j$(GRAPH_WSG_PARALLEL_JOBS) \
		$(foreach g,$(GRAPH_WSG_DATASETS_SG),graph-wsg-qemu-bbv-one-$(g)_sg) \
		$(foreach g,$(GRAPH_WSG_DATASETS_WSG),graph-wsg-qemu-bbv-one-$(g)_wsg)

graph-wsg-sift-gap: \
  $(foreach g,$(GRAPH_WSG_DATASETS_SG),graph_wsg_sift_bfs_$(g)_sg) \
  $(foreach g,$(GRAPH_WSG_DATASETS_SG),graph_wsg_sift_cc_$(g)_sg) \
  $(foreach g,$(GRAPH_WSG_DATASETS_SG),graph_wsg_sift_pr_$(g)_sg) \
  $(foreach g,$(GRAPH_WSG_DATASETS_WSG),graph_wsg_sift_sssp_$(g)_wsg)

# Fully parallel SIFT: all 20 jobs (5 graphs × bfs/cc/pr + 5 graphs × sssp) run concurrently.
# Parallelism = GRAPH_WSG_PARALLEL_JOBS (default: nproc).
graph-wsg-sift-gap-parallel:
	$(MAKE) -j$(GRAPH_WSG_PARALLEL_JOBS) graph-wsg-sift-gap

qemu-sift:
	@test -d "$(BENCH)" || (echo "ERROR: BENCH not found: $(BENCH)" && exit 2)
	@test -d "$(PRAVE_NEXT2_DIR)/sniper" || (echo "ERROR: expected Sniper under PRAVE_NEXT2_DIR/sniper (got: $(PRAVE_NEXT2_DIR)/sniper)" && exit 2)
	$(MAKE) docker-cmd CMD="make -C \"$(BENCH)\" runqemu-v VLEN=$(VLEN) TARGET_OS=$(TARGET_OS) SNIPER_ROOT=\"$(realpath $(PRAVE_NEXT2_DIR)/sniper)\" QEMU=\"$(QEMU)\" QEMU_LD_PREFIX=\"$(QEMU_LD_PREFIX)\""

# Build (rvv10.mk) then qemu-riscv64 once per ported benchmark (see scripts/qemu-smoke-graph-wsg.sh).
# Override GRAPH_WSG_QEMU_MAKEFLAGS= only if you intentionally want bare-metal under qemu (usually fails file I/O).
qemu-smoke-graph-wsg:
	@test -d "$(GRAPH_WSG_DIR)" || (echo "ERROR: $(GRAPH_WSG_DIR) not found" && exit 2)
	@test -f "$(GRAPH_WSG_DIR)/rvv10.mk" || (echo "ERROR: $(GRAPH_WSG_DIR)/rvv10.mk not found" && exit 2)
	@test -f "$(abspath scripts/qemu-smoke-graph-wsg.sh)" || (echo "ERROR: scripts/qemu-smoke-graph-wsg.sh not found" && exit 2)
	$(MAKE) docker-cmd CMD="export QEMU=\"$(QEMU)\"; export QEMU_CPU=\"$(GRAPH_WSG_QEMU_CPU)\"; export QEMU_LD_PREFIX=\"$(QEMU_LD_PREFIX)\"; export GRAPH_WSG_QEMU_MAKEFLAGS=\"$(GRAPH_WSG_QEMU_MAKEFLAGS)\"; export GRAPH_WSG_QEMU_EXTRA_CXX_FLAGS=\"$(GRAPH_WSG_QEMU_EXTRA_CXX_FLAGS)\"; export GRAPH_WSG_SMOKE_VERBOSE=\"$(GRAPH_WSG_SMOKE_VERBOSE)\"; export GRAPH_WSG_SMOKE_SHELL_TRACE=\"$(GRAPH_WSG_SMOKE_SHELL_TRACE)\"; bash \"$(abspath scripts/qemu-smoke-graph-wsg.sh)\" \"$(abspath $(GRAPH_WSG_DIR))\" \"$(GRAPH_WSG_QEMU_INPUT)\" $(GRAPH_WSG_QEMU_PORTED)"
	$(MAKE) docker-cmd CMD="export QEMU=\"$(QEMU)\"; export QEMU_CPU=\"$(GRAPH_WSG_QEMU_CPU)\"; export QEMU_LD_PREFIX=\"$(QEMU_LD_PREFIX)\"; export GRAPH_WSG_QEMU_MAKEFLAGS=\"$(GRAPH_WSG_QEMU_MAKEFLAGS)\"; export GRAPH_WSG_QEMU_EXTRA_CXX_FLAGS=\"$(GRAPH_WSG_QEMU_EXTRA_CXX_FLAGS)\"; export GRAPH_WSG_SMOKE_VERBOSE=\"$(GRAPH_WSG_SMOKE_VERBOSE)\"; export GRAPH_WSG_SMOKE_SHELL_TRACE=\"$(GRAPH_WSG_SMOKE_SHELL_TRACE)\"; export GRAPH_WSG_SMOKE_REBUILD=\"$(GRAPH_WSG_SMOKE_REBUILD)\"; bash \"$(abspath scripts/qemu-smoke-graph-wsg.sh)\" \"$(abspath $(GRAPH_WSG_DIR))\" \"$(GRAPH_WSG_QEMU_INPUT)\" $(GRAPH_WSG_QEMU_PORTED)"

# Production-style full check: ported bins × GRAPH_WSG_CHECK_GRAPHS under qemu-riscv64 (PASS required).
qemu-check-graph-wsg:
	@test -d "$(GRAPH_WSG_DIR)" || (echo "ERROR: $(GRAPH_WSG_DIR) not found" && exit 2)
	@test -f "$(GRAPH_WSG_DIR)/rvv10.mk" || (echo "ERROR: $(GRAPH_WSG_DIR)/rvv10.mk not found" && exit 2)
	@test -f "$(abspath scripts/qemu-smoke-graph-wsg.sh)" || (echo "ERROR: scripts/qemu-smoke-graph-wsg.sh not found" && exit 2)
	$(MAKE) docker-cmd CMD="export QEMU=\"$(QEMU)\"; export QEMU_CPU=\"$(GRAPH_WSG_QEMU_CPU)\"; export QEMU_LD_PREFIX=\"$(QEMU_LD_PREFIX)\"; export GRAPH_WSG_QEMU_MAKEFLAGS=\"$(GRAPH_WSG_QEMU_MAKEFLAGS)\"; export GRAPH_WSG_QEMU_EXTRA_CXX_FLAGS=\"\"; export GRAPH_WSG_SMOKE_VERBOSE=1; export GRAPH_WSG_SMOKE_SHELL_TRACE=0; export GRAPH_WSG_SMOKE_REBUILD=1; export GRAPH_WSG_SMOKE_GRAPHS=\"$(GRAPH_WSG_CHECK_GRAPHS)\"; bash \"$(abspath scripts/qemu-smoke-graph-wsg.sh)\" \"$(abspath $(GRAPH_WSG_DIR))\" \"$(firstword $(GRAPH_WSG_CHECK_GRAPHS))\" $(GRAPH_WSG_QEMU_PORTED)"

SNIPER_ROOT_ABS := $(realpath $(PRAVE_NEXT2_DIR)/sniper)
SPIKE_ROOT_ABS  := $(realpath $(PRAVE_NEXT2_DIR)/riscv-isa-sim)

# riscv64-unknown-elf-g++ in rivec1.0/_swaptions (RVV .S + C++; RVV_COMPILE_OPTIONS must be set)
RIVEC_RVV_GXXFLAGS := -march=rv64gcv -mabi=lp64d -O2 -DUSE_RISCV_VECTOR -I$(SNIPER_ROOT_ABS)/include

# Passed to scripts/rivec-riscv-shim (SimRoi / count_utils paths for rivec apps)
RIVEC_CPPFLAGS := -I$(SNIPER_ROOT_ABS)/include -I$(abspath rivec1.0/common)

# Build every rivec1.0 app dir from APPLICATION_DIRS in rivec1.0/Makefile (upstream list; includes _lavaMD, _matmul, _somier, …)
build-rivec:
	@test -d "$(PRAVE_NEXT2_DIR)/sniper" || (echo "ERROR: expected Sniper under PRAVE_NEXT2_DIR/sniper (got: $(PRAVE_NEXT2_DIR)/sniper)" && exit 2)
	@test -d "$(PRAVE_NEXT2_DIR)/riscv-isa-sim" || (echo "ERROR: expected riscv-isa-sim under PRAVE_NEXT2_DIR/riscv-isa-sim (got: $(PRAVE_NEXT2_DIR)/riscv-isa-sim)" && exit 2)
	@test -f rivec1.0/Makefile || (echo "ERROR: rivec1.0/Makefile not found" && exit 2)
	docker run --cap-add=SYS_PTRACE --security-opt="seccomp=unconfined" \
		--rm -t --memory=$(MEM_LIMIT) \
		-v "${HOME}:${HOME}" -v "/tmp:/tmp" \
		--user $(shell id -u):$(shell id -g) -w "${PWD}" \
		$(DOCKER_IMAGE) bash -lc 'set -u; \
			export SNIPER_ROOT="$(SNIPER_ROOT_ABS)"; export SPIKE_ROOT="$(SPIKE_ROOT_ABS)"; \
			export RIVEC_CPPFLAGS="$(RIVEC_CPPFLAGS)"; \
			export RISCV="$(RIVEC_RISCV)" LLVM="$(RIVEC_LLVM)" SYSROOT_DIR="$(RIVEC_SYSROOT)" GCC_TOOLCHAIN_DIR="$(RIVEC_GCC_TOOLCHAIN)"; \
			export RVV_COMPILE_OPTIONS="$(RIVEC_RVV_GXXFLAGS)"; \
			rivec_dirs=$$(sed -n "s/^APPLICATION_DIRS[[:space:]]*:=[[:space:]]*//p" rivec1.0/Makefile | head -1); \
			test -n "$$rivec_dirs" || (echo "ERROR: could not parse APPLICATION_DIRS from rivec1.0/Makefile" >&2 && exit 2); \
			fail=0; \
			for d in $$rivec_dirs; do \
				echo "== build-rivec: rivec1.0/$$d"; \
				mkdir -p "rivec1.0/$$d/bin" || true; \
				if ! make -C "rivec1.0/$$d" -k vector SNIPER_ROOT="$$SNIPER_ROOT" SPIKE_ROOT="$$SPIKE_ROOT" VLEN=$(VLEN); then \
					echo "!! build-rivec FAILED: rivec1.0/$$d (vector)" >&2; \
					fail=1; \
				fi; \
			done; \
			exit $$fail'

# graph-v-rvv10-wsg: RISC-V cross build (clang++/sysroot under /riscv in the work image). No Sniper/Spike required for compile.
build-graph-wsg:
	@test -d "$(GRAPH_WSG_DIR)" || (echo "ERROR: $(GRAPH_WSG_DIR) not found" && exit 2)
	@test -f "$(GRAPH_WSG_DIR)/rvv10.mk" || (echo "ERROR: $(GRAPH_WSG_DIR)/rvv10.mk not found" && exit 2)
	docker run --cap-add=SYS_PTRACE --security-opt="seccomp=unconfined" \
		--rm -t --memory=$(MEM_LIMIT) \
		-v "${HOME}:${HOME}" -v "/tmp:/tmp" \
		--user $(shell id -u):$(shell id -g) -w "${PWD}" \
		$(DOCKER_IMAGE) bash -lc 'set -u; set -e; echo "== build-graph-wsg: $(GRAPH_WSG_DIR)"; make -C "$(GRAPH_WSG_DIR)" -f rvv10.mk -j1 build ARCH=riscv'

clean-graph-wsg:
	@test -d "$(GRAPH_WSG_DIR)" || (echo "ERROR: $(GRAPH_WSG_DIR) not found" && exit 2)
	docker run --cap-add=SYS_PTRACE --security-opt="seccomp=unconfined" \
		--rm -t --memory=$(MEM_LIMIT) \
		-v "${HOME}:${HOME}" -v "/tmp:/tmp" \
		--user $(shell id -u):$(shell id -g) -w "${PWD}" \
		$(DOCKER_IMAGE) bash -lc 'set -u; echo "== clean-graph-wsg: $(GRAPH_WSG_DIR)"; make -C "$(GRAPH_WSG_DIR)" clean; make -C "$(GRAPH_WSG_DIR)" -f rvv10.mk clean'

# ============================================================================
# HPCG: vectorized HPCG-Benchmark for RVV1.0 (submodule: hpcg-v-rvv10)
# ============================================================================
HPCG_DIR     ?= hpcg-v-rvv10
HPCG_BIN_DIR ?= $(HPCG_DIR)/bin
HPCG_PROGRAM ?= xhpcg
# Cube problem sizes for SimPoint analysis. 8 = quickest smoke. 16/32/64
# scale up nicely; HPCG official runs typically use 104+.
HPCG_SIZES   ?= 8 16 32 64

# Cross-compile HPCG inside the docker image.
# Uses HPCG's own arch-based build with setup/Make.RISCV_RVV10 (added in
# hpcg-v-rvv10 commit 6f3b9cf), producing bin/xhpcg statically linked
# rv64gcv ELF.
build-hpcg:
	@test -d "$(HPCG_DIR)" || (echo "ERROR: $(HPCG_DIR) not found (run: git submodule update --init $(HPCG_DIR))" && exit 2)
	@test -f "$(HPCG_DIR)/setup/Make.RISCV_RVV10" || (echo "ERROR: $(HPCG_DIR)/setup/Make.RISCV_RVV10 not found" && exit 2)
	docker run --cap-add=SYS_PTRACE --security-opt="seccomp=unconfined" \
		--rm -t --memory=$(MEM_LIMIT) \
		-v "${HOME}:${HOME}" -v "/tmp:/tmp" \
		--user $(shell id -u):$(shell id -g) -w "${PWD}" \
		$(DOCKER_IMAGE) bash -lc 'set -eu; echo "== build-hpcg: $(HPCG_DIR)"; make -C "$(HPCG_DIR)" clean; make -C "$(HPCG_DIR)" arch=RISCV_RVV10 -j$$(nproc)'

clean-hpcg:
	@test -d "$(HPCG_DIR)" || (echo "ERROR: $(HPCG_DIR) not found" && exit 2)
	docker run --cap-add=SYS_PTRACE --security-opt="seccomp=unconfined" \
		--rm -t --memory=$(MEM_LIMIT) \
		-v "${HOME}:${HOME}" -v "/tmp:/tmp" \
		--user $(shell id -u):$(shell id -g) -w "${PWD}" \
		$(DOCKER_IMAGE) bash -lc 'set -u; echo "== clean-hpcg: $(HPCG_DIR)"; make -C "$(HPCG_DIR)" clean'

# Internal: run xhpcg under qemu with bbv+icount plugins.
# Unlike graph-wsg, the "workload" is generated at runtime from --nx/--ny/--nz,
# so no graph file decompression step.
hpcg-run-qemu-bbv:
	@test -f "$(HPCG_BIN_DIR)/$(HPCG_PROGRAM)" || (echo "ERROR: program not found: $(HPCG_BIN_DIR)/$(HPCG_PROGRAM) (run: make build-hpcg)" && exit 2)
	$(MAKE) docker-cmd CMD='set -euo pipefail; \
		export GRAPH_WSG_QEMU_PLUGIN_DIR1="$(GRAPH_WSG_QEMU_PLUGIN_DIR1)"; export GRAPH_WSG_QEMU_PLUGIN_DIR2="$(GRAPH_WSG_QEMU_PLUGIN_DIR2)"; \
		plugin_dir=$$$$(bash "$(GRAPH_WSG_QEMU_PLUGINS_SCRIPT)"); \
		test -f "$(SIMPOINT_BIN)" || echo "WARN: SIMPOINT_BIN not found (later simpoint step will fail): $(SIMPOINT_BIN)" >&2; \
		mkdir -p "$(DIR)"; \
		echo "== hpcg: qemu bbv icount: size=$(SIZE)x$(SIZE)x$(SIZE) out=$(DIR)"; \
		cd "$(DIR)"; \
		$(GRAPH_WSG_QEMU_ENV) "$(QEMU)" \
			-plugin "$$$$plugin_dir/libbbv.so,interval=$(GRAPH_WSG_INTERVAL),outfile=$(DIR)/bbv" \
			-plugin "$$$$plugin_dir/libicount.so,interval=$(GRAPH_WSG_INTERVAL)" \
			"$(abspath $(HPCG_BIN_DIR))/$(HPCG_PROGRAM)" --nx=$(SIZE) --ny=$(SIZE) --nz=$(SIZE) --rt=$(HPCG_RT) > "$(LOGFILE)" 2>&1'

# Internal: replay xhpcg under qemu with insnhist plugin at the simpoint-selected intervals.
hpcg-run-qemu-insnhist:
	$(MAKE) docker-cmd CMD='set -euo pipefail; \
		export GRAPH_WSG_QEMU_PLUGIN_DIR1="$(GRAPH_WSG_QEMU_PLUGIN_DIR1)"; export GRAPH_WSG_QEMU_PLUGIN_DIR2="$(GRAPH_WSG_QEMU_PLUGIN_DIR2)"; \
		plugin_dir=$$$$(bash "$(GRAPH_WSG_QEMU_PLUGINS_SCRIPT)"); \
		test -f "$(DIR)/results.simpts" || (echo "ERROR: missing $(DIR)/results.simpts; run simpoint first" >&2; exit 2); \
		test -f "$(DIR)/qemu.log.roi" || (echo "ERROR: missing $(DIR)/qemu.log.roi; run bbv first" >&2; exit 2); \
		base=$$$$(head -n 1 "$(DIR)/qemu.log.roi"); \
		start_points=$$$$(while read -r sp _; do echo $$$$(( $$$$base + sp )); done < "$(DIR)/results.simpts" | paste -sd/); \
		echo "== hpcg: insnhist start_points=$$$$start_points"; \
		cd "$(DIR)"; \
		$(GRAPH_WSG_QEMU_ENV) "$(QEMU)" \
			-plugin "$$$$plugin_dir/libinsnhist.so,interval=$(GRAPH_WSG_INTERVAL),start_points=$$$$start_points" \
			"$(abspath $(HPCG_BIN_DIR))/$(HPCG_PROGRAM)" --nx=$(SIZE) --ny=$(SIZE) --nz=$(SIZE) --rt=$(HPCG_RT) > qemu.insnhist.log 2>&1'

# Full HPCG BBV pipeline target: hpcg_bbv_<size>
# Output dir: $(GRAPH_WSG_OUT)/hpcg_<size>/
HPCG_RT ?= 1
hpcg_bbv_%: WORKDIR = $(GRAPH_WSG_OUT)/hpcg_$*
hpcg_bbv_%: SIZE    = $*
hpcg_bbv_%: LOGFILE = $(WORKDIR)/$(HPCG_PROGRAM).hpcg_$(SIZE).qemu.log
hpcg_bbv_%:
	@echo "==> hpcg BBV pipeline: size=$(SIZE)x$(SIZE)x$(SIZE)"
	$(MAKE) hpcg-run-qemu-bbv DIR=$(WORKDIR) SIZE=$(SIZE) LOGFILE=$(LOGFILE)
	awk '/Target instruction 0x00100013.*detected at instruction count: [0-9]+/ {match($$0, /instruction count: ([0-9]+)/, arr); print int(arr[1] / $(GRAPH_WSG_INTERVAL))}' $(LOGFILE) >  $(WORKDIR)/qemu.log.roi
	awk '/Target instruction 0x00200013.*detected at instruction count: [0-9]+/ {match($$0, /instruction count: ([0-9]+)/, arr); print int(arr[1] / $(GRAPH_WSG_INTERVAL))}' $(LOGFILE) >> $(WORKDIR)/qemu.log.roi
	gzip -f $(WORKDIR)/bbv.0.bb || true
	@roi_start_line=$$(head -n 1 $(WORKDIR)/qemu.log.roi); roi_end_line=$$(tail -n 1 $(WORKDIR)/qemu.log.roi); \
		gunzip -c $(WORKDIR)/bbv.0.bb.gz | head -n $$((roi_end_line + 1)) | tail -n +$$((roi_start_line + 1)) > $(WORKDIR)/bbv.0.roi.bb
	gzip -f $(WORKDIR)/bbv.0.roi.bb || true
	$(MAKE) graph-wsg-run-simpoint DIR=$(WORKDIR)
	$(MAKE) hpcg-run-qemu-insnhist DIR=$(WORKDIR) SIZE=$(SIZE)

# Meta: run hpcg_bbv_<size> for every HPCG_SIZES entry
.PHONY: hpcg-bbv-all hpcg-bbv-parallel
hpcg-bbv-all: $(foreach s,$(HPCG_SIZES),hpcg_bbv_$(s))

# Same set but launched all in parallel (one make -j$(GRAPH_WSG_PARALLEL_JOBS))
hpcg-bbv-parallel:
	$(MAKE) -j$(GRAPH_WSG_PARALLEL_JOBS) hpcg-bbv-all

# ============================================================================
# HPCG SIFT pipeline target: hpcg_sift_<size>
# ----------------------------------------------------------------------------
# Pre-requisite: `make hpcg_bbv_<size>` must have run for the same size, so
# that $(GRAPH_WSG_OUT)/hpcg_<size>/{qemu.log.roi,results.simpts} exist.
#
# Uses Sniper's QEMU frontend plugin (libqemu-frontend.so) and the SimPoint-
# selected representative interval to set fast_forward_target / detailed_target
# the same way graph-wsg-run-qemu-sift does.
#
# Note on use_roi=off: the plugin's `use_roi=on` code path only flips m_in_roi
# without invoking handleMagic(SIM_CMD_ROI_START), so no SIFT is actually
# recorded. We compute the absolute instruction count of the ROI start from
# qemu.log.roi (head value × interval) and add the simpoint offset, then use
# `use_roi=off` to drive recording purely by instruction count.
# ============================================================================

# Sniper QEMU frontend plugin (built in prave_next2/sniper with BUILD_QEMU=1)
HPCG_QEMU_SIFT_PLUGIN ?= $(SNIPER_ROOT)/frontend/qemu-frontend/libqemu-frontend.so
# Detailed-mode recording length, in units of GRAPH_WSG_INTERVAL (500K by default)
HPCG_DETAILED_INTERVALS ?= 3
# LD_LIBRARY_PATH needed inside the container for libqemu-frontend.so to find
# libxed.so (lives under SNIPER_ROOT/xed_kit/lib) and libsift.so etc.
HPCG_SIFT_LD_LIBRARY_PATH ?= $(SNIPER_ROOT)/xed_kit/lib:$(SNIPER_ROOT)/lib
# Cosmetic VLEN suffix in the output .sift filename (the actual VLEN used by
# qemu-riscv64 comes from GRAPH_WSG_QEMU_ENV's QEMU_CPU=vlen=... setting).
HPCG_SIFT_VLEN ?= 1024

.PHONY: hpcg-run-qemu-sift hpcg-sift-all hpcg-sift-parallel

# Internal: run xhpcg under qemu with Sniper qemu-frontend plugin to write SIFT.
hpcg-run-qemu-sift:
	@test -f "$(HPCG_QEMU_SIFT_PLUGIN)" || (echo "ERROR: missing Sniper QEMU frontend plugin: $(HPCG_QEMU_SIFT_PLUGIN) — build it via 'make BUILD_QEMU=1' in $(SNIPER_ROOT)" >&2; exit 2)
	@test -f "$(DIR)/qemu.log.roi" || (echo "ERROR: missing $(DIR)/qemu.log.roi; run 'make hpcg_bbv_$(SIZE)' first" >&2; exit 2)
	@test -f "$(DIR)/results.simpts" || (echo "ERROR: missing $(DIR)/results.simpts; run 'make hpcg_bbv_$(SIZE)' first" >&2; exit 2)
	@test -f "$(HPCG_BIN_DIR)/$(HPCG_PROGRAM)" || (echo "ERROR: program not found: $(HPCG_BIN_DIR)/$(HPCG_PROGRAM) (run: make build-hpcg)" >&2; exit 2)
	$(MAKE) docker-cmd CMD='set -euo pipefail; \
		export LD_LIBRARY_PATH="$(HPCG_SIFT_LD_LIBRARY_PATH):$$$${LD_LIBRARY_PATH:-}"; \
		fast_forward=$$$$(( ( $$$$(head -n1 "$(DIR)/qemu.log.roi") + $$$$(cut -f1 -d" " "$(DIR)/results.simpts") - 2 ) * $(GRAPH_WSG_INTERVAL) )); \
		detailed=$$$$(( $(HPCG_DETAILED_INTERVALS) * $(GRAPH_WSG_INTERVAL) )); \
		echo "== hpcg: sift size=$(SIZE) ff=$$$$fast_forward detailed=$$$$detailed out=$(DIR)/xhpcg_v$(HPCG_SIFT_VLEN).sift"; \
		mkdir -p "$(DIR)"; \
		cd "$(DIR)"; \
		$(GRAPH_WSG_QEMU_ENV) "$(QEMU)" \
			-plugin "$(HPCG_QEMU_SIFT_PLUGIN),verbose=on,use_roi=off,blocksize=10000000,fast_forward_target=$$$$fast_forward,detailed_target=$$$$detailed,output_file=$(DIR)/xhpcg_v$(HPCG_SIFT_VLEN)" \
			"$(abspath $(HPCG_BIN_DIR))/$(HPCG_PROGRAM)" --nx=$(SIZE) --ny=$(SIZE) --nz=$(SIZE) --rt=$(HPCG_RT) > "$(DIR)/xhpcg_v$(HPCG_SIFT_VLEN).sift.log" 2>&1'

# Public target: hpcg_sift_<size> — relies on $(GRAPH_WSG_OUT)/hpcg_<size>/ being prepared by hpcg_bbv_<size>
hpcg_sift_%: WORKDIR = $(GRAPH_WSG_OUT)/hpcg_$*
hpcg_sift_%: SIZE    = $*
hpcg_sift_%:
	@echo "==> hpcg SIFT pipeline: size=$(SIZE)x$(SIZE)x$(SIZE)"
	$(MAKE) hpcg-run-qemu-sift DIR=$(WORKDIR) SIZE=$(SIZE)

# Meta: run hpcg_sift_<size> for every HPCG_SIZES entry
hpcg-sift-all: $(foreach s,$(HPCG_SIZES),hpcg_sift_$(s))

# Same set but launched in parallel
hpcg-sift-parallel:
	$(MAKE) -j$(GRAPH_WSG_PARALLEL_JOBS) hpcg-sift-all

# Quick smoke run (no plugins, prints HPCG output) — analogous to qemu-smoke-graph-wsg.
qemu-smoke-hpcg:
	@test -f "$(HPCG_BIN_DIR)/$(HPCG_PROGRAM)" || (echo "ERROR: program not found: $(HPCG_BIN_DIR)/$(HPCG_PROGRAM) (run: make build-hpcg)" && exit 2)
	$(MAKE) docker-cmd CMD='set -eu; cd "$(HPCG_BIN_DIR)"; \
		$(GRAPH_WSG_QEMU_ENV) "$(QEMU)" ./$(HPCG_PROGRAM) --nx=$(or $(NX),8) --ny=$(or $(NY),8) --nz=$(or $(NZ),8) --rt=$(or $(RT),1)'

build-all:
	@test -d "$(PRAVE_NEXT2_DIR)/sniper" || (echo "ERROR: expected Sniper under PRAVE_NEXT2_DIR/sniper (got: $(PRAVE_NEXT2_DIR)/sniper)" && exit 2)
	@test -d "$(PRAVE_NEXT2_DIR)/riscv-isa-sim" || (echo "ERROR: expected riscv-isa-sim under PRAVE_NEXT2_DIR/riscv-isa-sim (got: $(PRAVE_NEXT2_DIR)/riscv-isa-sim)" && exit 2)
	docker run --cap-add=SYS_PTRACE --security-opt="seccomp=unconfined" \
		--rm -t --memory=$(MEM_LIMIT) \
		-v "${HOME}:${HOME}" -v "/tmp:/tmp" \
		--user $(shell id -u):$(shell id -g) -w "${PWD}" \
		$(DOCKER_IMAGE) bash -lc 'set -u; \
			export SNIPER_ROOT="$(SNIPER_ROOT_ABS)"; export SPIKE_ROOT="$(SPIKE_ROOT_ABS)"; \
			export RIVEC_CPPFLAGS="$(RIVEC_CPPFLAGS)"; \
			benches=$$(find microbenchmarks rivec1.0 -mindepth 2 -maxdepth 2 -name Makefile -print \
				| xargs -r grep -El "^[[:space:]]*include[[:space:]].*scripts/runspike\\.mk" \
				| xargs -r -n1 dirname | sort -u); \
			if [ "$(INCLUDE_FFTW3)" != "1" ]; then benches=$$(printf "%s\n" $$benches | grep -v "^rivec1\\.0/_fftw3$$" || true); fi; \
			fail=0; \
			for b in $$benches; do \
				echo "== build-all: $$b"; \
				if ! make -C "$$b" -k vector SNIPER_ROOT="$$SNIPER_ROOT" SPIKE_ROOT="$$SPIKE_ROOT" VLEN=$(VLEN); then \
					echo "!! build-all FAILED: $$b (vector)" >&2; \
					fail=1; \
				fi; \
				case "$$b" in rivec1.0/*) continue ;; esac; \
				if ! grep -Eq "^[[:space:]]*serial_target[[:space:]]*=[[:space:]]*DUMMY([[:space:]]|$$)" "$$b/Makefile"; then \
					if ! make -C "$$b" -k scalar SNIPER_ROOT="$$SNIPER_ROOT" SPIKE_ROOT="$$SPIKE_ROOT" VLEN=$(VLEN); then \
						echo "!! build-all FAILED: $$b (scalar)" >&2; \
						fail=1; \
					fi; \
				fi; \
			done; \
			export RISCV="$(RIVEC_RISCV)" LLVM="$(RIVEC_LLVM)" SYSROOT_DIR="$(RIVEC_SYSROOT)" GCC_TOOLCHAIN_DIR="$(RIVEC_GCC_TOOLCHAIN)"; \
			export RVV_COMPILE_OPTIONS="$(RIVEC_RVV_GXXFLAGS)"; \
			rivec_dirs=$$(sed -n "s/^APPLICATION_DIRS[[:space:]]*:=[[:space:]]*//p" rivec1.0/Makefile | head -1); \
			if [ -n "$$rivec_dirs" ]; then \
				for d in $$rivec_dirs; do \
					echo "== build-all: rivec1.0/$$d"; \
					mkdir -p "rivec1.0/$$d/bin" || true; \
					if ! make -C "rivec1.0/$$d" -k vector SNIPER_ROOT="$$SNIPER_ROOT" SPIKE_ROOT="$$SPIKE_ROOT" VLEN=$(VLEN); then \
						echo "!! build-all FAILED: rivec1.0/$$d (vector)" >&2; \
						fail=1; \
					fi; \
				done; \
			fi; \
			exit $$fail'

sift-all:
	@test -d "$(PRAVE_NEXT2_DIR)/sniper" || (echo "ERROR: expected Sniper under PRAVE_NEXT2_DIR/sniper (got: $(PRAVE_NEXT2_DIR)/sniper)" && exit 2)
	@test -d "$(PRAVE_NEXT2_DIR)/riscv-isa-sim" || (echo "ERROR: expected riscv-isa-sim under PRAVE_NEXT2_DIR/riscv-isa-sim (got: $(PRAVE_NEXT2_DIR)/riscv-isa-sim)" && exit 2)
	docker run --cap-add=SYS_PTRACE --security-opt="seccomp=unconfined" \
		--rm -t --memory=$(MEM_LIMIT) \
		-v "${HOME}:${HOME}" -v "/tmp:/tmp" \
		--user $(shell id -u):$(shell id -g) -w "${PWD}" \
		$(DOCKER_IMAGE) bash -lc 'set -u; \
			export SNIPER_ROOT="$(SNIPER_ROOT_ABS)"; export SPIKE_ROOT="$(SPIKE_ROOT_ABS)"; \
			export RIVEC_CPPFLAGS="$(RIVEC_CPPFLAGS)"; \
			benches=$$(find microbenchmarks rivec1.0 -mindepth 2 -maxdepth 2 -name Makefile -print \
				| xargs -r grep -El "^[[:space:]]*include[[:space:]].*scripts/runspike\\.mk" \
				| xargs -r -n1 dirname | sort -u); \
			if [ "$(INCLUDE_FFTW3)" != "1" ]; then benches=$$(printf "%s\n" $$benches | grep -v "^rivec1\\.0/_fftw3$$" || true); fi; \
			fail=0; \
			for b in $$benches; do \
				echo "== sift-all: $$b"; \
				if ! make -C "$$b" -k runspike-v SNIPER_ROOT="$$SNIPER_ROOT" SPIKE_ROOT="$$SPIKE_ROOT" VLEN=$(VLEN); then \
					echo "!! sift-all FAILED: $$b" >&2; \
					fail=1; \
				fi; \
			done; \
			exit $$fail'

qemu-sift-all:
	@test -d "$(PRAVE_NEXT2_DIR)/sniper" || (echo "ERROR: expected Sniper under PRAVE_NEXT2_DIR/sniper (got: $(PRAVE_NEXT2_DIR)/sniper)" && exit 2)
	docker run --cap-add=SYS_PTRACE --security-opt="seccomp=unconfined" \
		--rm -t --memory=$(MEM_LIMIT) \
		-v "${HOME}:${HOME}" -v "/tmp:/tmp" \
		--user $(shell id -u):$(shell id -g) -w "${PWD}" \
		$(DOCKER_IMAGE) bash -lc 'set -u; \
			export SNIPER_ROOT="$(SNIPER_ROOT_ABS)"; \
			benches=$$(find microbenchmarks rivec1.0 -mindepth 2 -maxdepth 2 -name Makefile -print \
				| xargs -r grep -El "^[[:space:]]*include[[:space:]].*scripts/runqemu\\.mk" \
				| xargs -r -n1 dirname | sort -u); \
			fail=0; \
			for b in $$benches; do \
				echo "== qemu-sift-all: $$b"; \
				if ! make -C "$$b" -k runqemu-v SNIPER_ROOT="$$SNIPER_ROOT" VLEN=$(VLEN) TARGET_OS=$(TARGET_OS) QEMU="$(QEMU)" QEMU_LD_PREFIX="$(QEMU_LD_PREFIX)"; then \
					echo "!! qemu-sift-all FAILED: $$b" >&2; \
					fail=1; \
				fi; \
			done; \
			exit $$fail'

clean:
	docker run --cap-add=SYS_PTRACE --security-opt="seccomp=unconfined" \
		--rm -t --memory=$(MEM_LIMIT) \
		-v "${HOME}:${HOME}" -v "/tmp:/tmp" \
		--user $(shell id -u):$(shell id -g) -w "${PWD}" \
		$(DOCKER_IMAGE) bash -lc 'set -u; \
			benches=$$(find microbenchmarks rivec1.0 -mindepth 2 -maxdepth 2 -name Makefile -print \
				| xargs -r grep -El "^[[:space:]]*include[[:space:]].*scripts/runspike\\.mk" \
				| xargs -r -n1 dirname | sort -u); \
			for b in $$benches; do \
				echo "== clean: $$b"; \
				make -C "$$b" clean || true; \
			done; \
			echo "== clean: rivec1.0 (APPLICATION_DIRS via top Makefile)"; \
			make -C rivec1.0 clean || true; \
			rm -f build.log || true'

clean-rivec:
	docker run --cap-add=SYS_PTRACE --security-opt="seccomp=unconfined" \
		--rm -t --memory=$(MEM_LIMIT) \
		-v "${HOME}:${HOME}" -v "/tmp:/tmp" \
		--user $(shell id -u):$(shell id -g) -w "${PWD}" \
		$(DOCKER_IMAGE) bash -lc 'make -C rivec1.0 clean || true'

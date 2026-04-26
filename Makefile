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
	UBUNTU_VERSION  = 20.04
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

.PHONY: help docker-build docker-shell docker-cmd sift build-all build-rivec sift-all clean clean-rivec

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
	@echo "  build-all            Compile microbenchmarks (runspike.mk) + rivec1.0 APPLICATION_DIRS (vector) (in Docker)"
	@echo "  build-rivec          Compile only rivec1.0 benchmarks listed in rivec1.0/Makefile APPLICATION_DIRS (in Docker)"
	@echo "  sift-all             Spike SIFT only for dirs that include scripts/runspike.mk (upstream rivec apps usually do not)"
	@echo "  clean                Clean microbenchmark runspike dirs + rivec1.0 top-level clean (in Docker)"
	@echo "  clean-rivec          Run make -C rivec1.0 clean (in Docker)"
	@echo ""
	@echo "Vars:"
	@echo "  LLVM=16|18|19            (default: 16)"
	@echo "  PRAVE_NEXT2_DIR=...      (default: ../prave_next2)"
	@echo "  BENCH=...                (default: microbenchmarks/rvv_saxpy)"
	@echo "  VLEN=...                 (default: 256)"
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
		$(DOCKER_IMAGE) bash -lc "$$RUN_CMD"

# Generate a .sift file by running Spike with --sift (see scripts/runspike.mk)
BENCH ?= microbenchmarks/rvv_saxpy
VLEN ?= 256
# Building `rivec1.0/_fftw3` can take a long time because it bootstraps
# and builds FFTW from source. Keep it opt-in for `build-all`/`sift-all`.
INCLUDE_FFTW3 ?= 0
sift:
	@test -d "$(BENCH)" || (echo "ERROR: BENCH not found: $(BENCH)" && exit 2)
	@test -d "$(PRAVE_NEXT2_DIR)/sniper" || (echo "ERROR: expected Sniper under PRAVE_NEXT2_DIR/sniper (got: $(PRAVE_NEXT2_DIR)/sniper)" && exit 2)
	@test -d "$(PRAVE_NEXT2_DIR)/riscv-isa-sim" || (echo "ERROR: expected riscv-isa-sim under PRAVE_NEXT2_DIR/riscv-isa-sim (got: $(PRAVE_NEXT2_DIR)/riscv-isa-sim)" && exit 2)
	$(MAKE) docker-cmd CMD="make -C \"$(BENCH)\" runspike-v VLEN=$(VLEN) SNIPER_ROOT=\"$(realpath $(PRAVE_NEXT2_DIR)/sniper)\" SPIKE_ROOT=\"$(realpath $(PRAVE_NEXT2_DIR)/riscv-isa-sim)\""

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

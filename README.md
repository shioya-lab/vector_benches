# vector_benches

This repository contains benchmarks that can generate **Spike SIFT traces** (i.e. `.sift` files) using Spike's `--sift` option.

To make this repo self-contained, `Dockerfile*` are **copied from `prave_next2`**, so you can build the same Docker environment directly from here.

## Requirements

- Docker
- A local checkout of `prave_next2` is still recommended (default: `../prave_next2`) to provide:
  - `sniper` (headers like `sim_api.h`)
  - `riscv-isa-sim` (Spike binary)

You can override the location via `PRAVE_NEXT2_DIR=...`.

## Quick start

### 1) Build the Docker image

```bash
make docker-build
```

Select LLVM version (same branching as the original `prave_next2` environment):

```bash
make docker-build LLVM=18
```

### 2) Generate a SIFT file (example)

Generate a `.sift` for `microbenchmarks/pointer_chase` with `VLEN=256`:

```bash
make sift PRAVE_NEXT2_DIR=../prave_next2 BENCH=microbenchmarks/pointer_chase VLEN=256
```

The output will be created under the benchmark directory (e.g. `pointer_chase_v256.sift`).

### 2d) Generate a SIFT file via QEMU user-mode (experimental)

This uses Sniper's QEMU frontend plugin (`sniper/frontend/qemu-frontend/libqemu-frontend.so`) and requires:

- `prave_next2/sniper` built with `BUILD_QEMU=1` (and `RV8_HOME` available)
- the benchmark binary to be runnable under `qemu-riscv64` (typically `TARGET_OS=linux`)

Example:

```bash
make qemu-sift PRAVE_NEXT2_DIR=../prave_next2 BENCH=microbenchmarks/rvv_saxpy VLEN=256 QEMU=qemu-riscv64
```

### 2b) Compile everything (microbenchmarks)

This walks `microbenchmarks/**` and builds targets that include `scripts/runspike.mk`.

```bash
make build-all PRAVE_NEXT2_DIR=../prave_next2 VLEN=256
```

### 2c) Generate Spike SIFT for everything (microbenchmarks)

This runs `runspike-v` for the same set of microbenchmarks.

```bash
make sift-all PRAVE_NEXT2_DIR=../prave_next2 VLEN=256
```

### 3) Open an interactive shell in the Docker environment

```bash
make docker-shell
```

## Notes

- The actual `.sift` generation rules come from `scripts/runspike.mk` (targets like `runspike-v`).
- `make sift` simply runs `make -C <BENCH> runspike-v ...` inside the Docker container.

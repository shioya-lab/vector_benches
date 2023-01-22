RISCV_GCC = riscv64-unknown-elf-gcc

SOURCE_FILES += rvv_gather_scatter_e16.c

APP_NAME = rvv_gather_scatter_e16
PK =  # this test case doesn't use PK

RISCV_GCC = riscv$(XLEN)-unknown-elf-gcc
RISCV_GCC_VEC_OPTS ?= \
	-O2 \
	-march=rv64gcv \
	--sysroot=/home/kimura/riscv64/riscv64-unknown-elf \
	-DPREALLOCATE=1 -mcmodel=medany \
	-DUSE_RISCV_VECTOR \
	-ffast-math -fno-common -fno-builtin-printf

RISCV_GCC_SCALAR_OPTS ?= \
	-march=rv64gc \
	-O1 \
	-DPREALLOCATE=1 -mcmodel=medany \
	-fno-common -fno-builtin-printf

include ../compile.mk
include ../runspike.mk

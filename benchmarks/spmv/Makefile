rvv_target = spmv_vector
serial_target = spmv_scalar

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

#	-ffast-math
#	-O2 \

APP_NAME = spmv

PK =

.PHONY: hoge

hoge: $(rvv_target)

include ../compile.mk
include ../runspike.mk

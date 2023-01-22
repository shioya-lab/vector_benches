.PHONY : run

SOURCE_FILES += main.c

APP_NAME = memcpy_scalar

RISCV_GCC = riscv64-unknown-elf-gcc

RISCV_GCC_VEC_OPTS = -march=rv64imafd -DPREALLOCATE=1 -static -mcmodel=medany -std=gnu99 -O2 \
	-ffast-math -fno-common -fno-builtin -fno-builtin-printf -nostdlib -nostartfiles -lm -lgcc -T test.ld
RISCV_GCC_SCALAR_OPTS = $(RISCV_GCC_VEC_OPTS)

include ../compile.mk
include ../runspike.mk

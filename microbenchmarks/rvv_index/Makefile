.PHONY : run

run:
	$(MAKE) runsniper-ooo-v runsniper-vio-v runsniper-ino-v

SOURCE_FILES += rvv_index.c

APP_NAME = rvv_index
serial_target = DUMMY

include ../microbenches.mk

# GCC 13 may ICE in the RISC-V vsetvl pass at -O2 for some RVV intrinsic patterns
# used by this benchmark. Keep the benchmark intrinsic-based, but compile it with
# a lower optimization level to avoid the compiler bug.
RISCV_GCC_VEC_OPTS := -O0 $(filter-out -O%,$(RISCV_GCC_VEC_OPTS))

include ../../scripts/compile.mk
include ../../scripts/runspike.mk

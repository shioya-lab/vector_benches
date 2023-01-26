RISCV_GCC = riscv64-unknown-elf-gcc

run:
	$(MAKE) runsniper-ooo-v runsniper-vio-v runsniper-ino-v

SOURCE_FILES += rvv_gather_scatter_e8.c

APP_NAME = rvv_gather_scatter_e8
PK =  # this test case doesn't use PK
serial_target = DUMMY

include ../microbenches.mk
include ../../scripts/compile.mk
include ../../scripts/runspike.mk

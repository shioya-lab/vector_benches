.PHONY : run

run:
	$(MAKE) runsniper-ooo-v runsniper-vio-v runsniper-ino-v

APP_NAME=00_undepend_loop

SOURCE_FILES += rvv_memcpy.c
SOURCE_FILES += memcpy.S

serial_target = DUMMY

include ../microbenches.mk
include ../../scripts/compile.mk
include ../../scripts/runspike.mk

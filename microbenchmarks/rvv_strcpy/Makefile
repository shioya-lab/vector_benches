.PHONY : run

run:
	$(MAKE) runsniper-ooo-v runsniper-vio-v runsniper-ino-v

SOURCE_FILES += rvv_strcpy.c

APP_NAME = rvv_strcpy
serial_target = DUMMY

include ../microbenches.mk
include ../../scripts/compile.mk
include ../../scripts/runspike.mk

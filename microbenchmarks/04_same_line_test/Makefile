.PHONY : run

run:
	$(MAKE) runsniper-ooo-v

APP_NAME=04_same_line_test

SOURCE_FILES += rvv_memcpy.c
SOURCE_FILES += memcpy.S

serial_target = DUMMY

include ../microbenches.mk
include ../../scripts/compile.mk
include ../../scripts/runspike.mk

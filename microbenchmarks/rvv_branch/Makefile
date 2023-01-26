.PHONY : run

run:
	$(MAKE) runsniper-ooo-v runsniper-vio-v runsniper-ino-v

SOURCE_FILES = rvv_branch.c

APP_NAME = rvv_branch
serial_target = DUMMY

include ../microbenches.mk
include ../../scripts/compile.mk
include ../../scripts/runspike.mk

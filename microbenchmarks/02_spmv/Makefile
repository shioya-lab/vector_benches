.PHONY : run

run:
	$(MAKE) runsniper-ooo-v runsniper-vio-v runsniper-ino-v

APP_NAME=02_spmv

SOURCE_FILES += spmv_main.c
SOURCE_FILES += spmv_vector.S

serial_target = DUMMY

include ../microbenches.mk
include ../../scripts/compile.mk
include ../../scripts/runspike.mk

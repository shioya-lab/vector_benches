.PHONY : run
run:
	$(MAKE) runsniper-ooo-v runsniper-vio-v runsniper-ino-v

SOURCE_FILES += main.c
SOURCE_FILES += memcpy.S

APP_NAME = memcpy_vector
serial_target = DUMMY

include ../microbenches.mk
include ../../scripts/compile.mk
include ../../scripts/runspike.mk

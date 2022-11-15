.PHONY : run

SOURCE_FILES = main.c

include common.mk

CFLAGS = -march=rv64gcv -DPREALLOCATE=1 -static -mcmodel=medany -std=gnu99 -O2 \
	-ffast-math -fno-common -fno-builtin -fno-builtin-printf -nostdlib -nostartfiles -lm -lgcc -T test.ld

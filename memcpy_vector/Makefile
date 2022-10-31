.PHONY : run

include common.mk

SNIPER_ROOT = ../../sniper
SPIKE = $(SNIPER_ROOT)/riscv/riscv-tools/RV64G/build-isa-sim/spike

debug: test.sift
	$(SNIPER_ROOT)/run-sniper -v -c $(SNIPER_ROOT)/config/riscv.cfg --traces=test.sift --gdb

CFLAGS = -march=rv64gcv -DPREALLOCATE=1 -static -mcmodel=medany -std=gnu99 -O3 \
	-ffast-math -fno-common -fno-builtin -fno-builtin-printf -nostdlib -nostartfiles -lm -lgcc -T test.ld

test.elf: crt.S syscalls.c main.c memcpy.S
	riscv64-unknown-elf-gcc $(CFLAGS) $^ -o $@
	riscv64-unknown-elf-objdump -D $@ > $@.dmp

clean:
	$(RM) -rf test.elf.dmp test.elf *.log *.out *.info *.sift* *.sqlite3

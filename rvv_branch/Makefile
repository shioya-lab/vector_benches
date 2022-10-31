.PHONY : run

include common.mk

SNIPER_ROOT = ../../sniper
SPIKE = $(SNIPER_ROOT)/riscv/riscv-tools/RV64G/build-isa-sim/spike
PK    = $(SNIPER_ROOT)/riscv/riscv-tools/RV64G/build-pk/pk

debug: test.sift
	$(SNIPER_ROOT)/run-sniper -v -c $(SNIPER_ROOT)/config/riscv.cfg --traces=test.sift --gdb

CFLAGS = -march=rv64gcv -DPREALLOCATE=1 -static -mcmodel=medany -std=gnu99 -O2 \
	-ffast-math -fno-common -fno-builtin -fno-builtin-printf -nostdlib -nostartfiles -lm -lgcc -T test.ld

test.elf: rvv_branch.c
	riscv64-unknown-elf-gcc -march=rv64gcv -O3 $^ -o $@
	riscv64-unknown-elf-objdump -D $@ > $@.dmp

clean:
	$(RM) -rf test.elf.dmp test.elf *.log *.out *.info *.sift* *.sqlite3

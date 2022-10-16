.PHONY:

.PHONY : run

SNIPER_ROOT = ../../sniper
SPIKE = $(SNIPER_ROOT)/riscv/riscv-tools/RV64G/build-isa-sim/spike
PK    = $(SNIPER_ROOT)/riscv/riscv-tools/RV64G/build-pk/pk

CFLAGS = -march=rv64imafdc -DPREALLOCATE=1 -static -mcmodel=medany -std=gnu99 -O2 \
	-ffast-math -fno-common -fno-builtin -fno-builtin-printf -nostdlib -nostartfiles -lm -lgcc -T test.ld

run: test.elf
	$(SPIKE) -l --isa=rv64gc --sift test.sift $^ > test.spike.log 2>&1
	$(SNIPER_ROOT)/run-sniper -v -c ../../sniper/config/riscv.cfg --traces=test.sift --viz > cycle.log 2>&1

test.elf: crt.S syscalls.c main.c
	riscv64-unknown-elf-gcc $(CFLAGS) $^ -o $@
	riscv64-unknown-elf-objdump -D $@ > $@.dmp

debug: test.elf
	$(SPIKE) -l --isa=rv64gc --sift test.sift $^ > test.spike.log 2>&1
	$(SNIPER_ROOT)/run-sniper -v -c ../../sniper/config/riscv.cfg --gdb --gdb-wait --traces=test.sift --viz

clean:
	$(RM) -rf test.elf.dmp test.elf

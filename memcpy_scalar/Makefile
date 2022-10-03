.PHONY:

all: run

CFLAGS = -march=rv64imafdc -DPREALLOCATE=1 -static -mcmodel=medany -std=gnu99 -O2 \
	-ffast-math -fno-common -fno-builtin -fno-builtin-printf -nostdlib -nostartfiles -lm -lgcc -T test.ld

test.elf: crt.S syscalls.c main.c
	riscv64-unknown-elf-gcc $(CFLAGS) $^ -o $@
	riscv64-unknown-elf-objdump -D $@ > $@.dmp

run: test.elf
	../../sniper/riscv/riscv-tools/RV64G/build-isa-sim/spike -l --isa=rv64gc --sift memcpy.sift $^ > test.spike.log 2>&1
	../../sniper/run-sniper -v -c ../../sniper/config/riscv.cfg --traces=memcpy.sift --viz > cycle.log
	python3 ./sniper2mcpat.py sim.stats.sqlite3 sim.stats.out > sim.stats.sqlite3.dmp

debug: test.elf
	../../sniper/riscv/riscv-tools/RV64G/build-isa-sim/spike -l --isa=rv64gc --sift memcpy.sift $^ > test.spike.log 2>&1
	../../sniper/run-sniper -v -c ../../sniper/config/riscv.cfg --gdb --gdb-wait --traces=memcpy.sift --viz

clean:
	$(RM) -rf test.elf.dmp test.elf

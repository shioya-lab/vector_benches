.PHONY:

all: run

CFLAGS = -march=rv64imafdc -DPREALLOCATE=1 -static -mcmodel=medany -std=gnu99 -O2 \
	-ffast-math -fno-common -fno-builtin -fno-builtin-printf -nostdlib -nostartfiles -lm -lgcc -T test.ld

test.elf: crt.S syscalls.c main.c
	riscv64-unknown-elf-gcc $(CFLAGS) $^ -o $@
	riscv64-unknown-elf-objdump -D $@ > $@.dmp

run: test.elf
	../../sniper/riscv/riscv-tools/RV64G/build-isa-sim/spike -l --isa=rv64gc --sift memcpy.sift $@ &> test.spike.log
	../../sniper/run-sniper -v -c ../../sniper/config/riscv.cfg --traces=memcpy.sift > cycle.log

clean:
	$(RM) -rf test.elf.dmp test.elf

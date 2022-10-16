.PHONY : run

SNIPER_ROOT = ../../sniper
SPIKE = $(SNIPER_ROOT)/riscv/riscv-tools/RV64G/build-isa-sim/spike

run: test.sift
	$(SNIPER_ROOT)/run-sniper -v -c $(SNIPER_ROOT)/config/riscv.cfg --traces=test.sift > cycle.log 2>&1

debug: test.sift
	$(SNIPER_ROOT)/run-sniper -v -c $(SNIPER_ROOT)/config/riscv.cfg --traces=test.sift --gdb

test.sift : test.elf
	$(SPIKE) -l --isa=rv64gcv --log-commits --sift $@ pk test.elf > test.spike.log 2>&1
	hexdump -C $@ > $@.hex
	$(SNIPER_ROOT)/sift/siftdump $@ > $@.dmp 2>&1

CFLAGS = -march=rv64gcv -DPREALLOCATE=1 -static -mcmodel=medany -std=gnu99 -O2 \
	-ffast-math -fno-common -fno-builtin -fno-builtin-printf -lm -lgcc

test.elf: main.c memcpy.S
	riscv64-unknown-linux-gnu-gcc $(CFLAGS) $^ -o $@
	riscv64-unknown-linux-gnu-objdump -D $@ > $@.dmp

clean:
	$(RM) -rf test.elf.dmp test.elf *.log *.out *.info *.sift* *.sqlite3

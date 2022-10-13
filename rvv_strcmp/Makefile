.PHONY : run

SNIPER_ROOT = ../../sniper
SPIKE = $(SNIPER_ROOT)/riscv/riscv-tools/RV64G/build-isa-sim/spike
PK    = $(SNIPER_ROOT)/riscv/riscv-tools/RV64G/build-pk/pk

run: memcpy.sift
	$(SNIPER_ROOT)/run-sniper -v -c $(SNIPER_ROOT)/config/riscv.cfg --traces=memcpy.sift > cycle.log 2>&1

debug: memcpy.sift
	$(SNIPER_ROOT)/run-sniper -v -c $(SNIPER_ROOT)/config/riscv.cfg --traces=memcpy.sift --gdb

memcpy.sift : test.elf
	$(SPIKE) -l --isa=rv64gcv --log-commits --sift $@ $(PK) test.elf > test.spike.log 2>&1
	hexdump -C $@ > $@.hex
	$(SNIPER_ROOT)/sift/siftdump $@ > $@.dmp 2>&1

CFLAGS = -march=rv64imafdcv -DPREALLOCATE=1 -static -mcmodel=medany -std=gnu99 -O2 \
	-ffast-math -fno-common -fno-builtin -fno-builtin-printf -nostdlib -nostartfiles -lm -lgcc -T test.ld

test.elf: rvv_strncpy.c
	riscv64-unknown-elf-gcc -march=rv64gcv -O3 $^ -o $@
	riscv64-unknown-elf-objdump -D $@ > $@.dmp

clean:
	$(RM) -rf test.elf.dmp test.elf *.log *.out *.info *.sift* *.sqlite3

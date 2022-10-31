SNIPER_ROOT = ../../sniper
SPIKE = $(SNIPER_ROOT)/../riscv-isa-sim/spike
PK = $(HOME)/riscv64/riscv64-unknown-elf/bin/pk

run: test.sift
	$(SNIPER_ROOT)/run-sniper -v -c $(SNIPER_ROOT)/config/riscv-mediumboom.cfg --traces=test.sift > cycle.log 2>&1
	mv o3_trace.out o3_trace.outoforder.out

debug: test.sift
	$(SNIPER_ROOT)/run-sniper -v -c $(SNIPER_ROOT)/config/riscv-mediumboom.cfg --traces=test.sift --gdb

debug_cui: test.sift
	$(SNIPER_ROOT)/run-sniper -v -c $(SNIPER_ROOT)/config/riscv-mediumboom.cfg --traces=test.sift --gdb --gdb-wait

run-io: test.sift # Inorder Implementation
	$(SNIPER_ROOT)/run-sniper -v -c $(SNIPER_ROOT)/config/riscv-inorderboom.cfg --traces=test.sift > cycle.log 2>&1
	mv o3_trace.out o3_trace.inorder.out

test.sift : test.elf
	$(SPIKE) -l --isa=rv64gcv --log-commits --sift $@ $(PK) test.elf > test.spike.log 2>&1
	hexdump -C $@ > $@.hex
	$(SNIPER_ROOT)/sift/siftdump $@ > $@.dmp 2>&1

test.elf: $(SOURCE_FILES)
	riscv64-unknown-elf-gcc -march=rv64gv -O3 $^ -o $@  -I../../sniper/include -I../common/
	riscv64-unknown-elf-objdump -D $@ > $@.dmp

clean:
	$(RM) -rf test.elf.dmp test.elf *.log *.out *.info *.sift* *.sqlite3 *.cfg *.dmp

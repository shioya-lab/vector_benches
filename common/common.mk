SNIPER_ROOT = ../../sniper
SPIKE = $(SNIPER_ROOT)/../riscv-isa-sim/spike
PK = $(HOME)/riscv64imafd/riscv64-unknown-elf/bin/pk

run-ooo: test.sift
	$(SNIPER_ROOT)/run-sniper -v -c $(SNIPER_ROOT)/config/riscv-mediumboom.cfg --traces=test.sift > cycle.ooo.log 2>&1
	grep rdcycle -B2 cycle.ooo.log | grep Running | awk '{ if(NR%2==1) { start=$$3 } else { print $$3-start} }' > cycle.ooo
	tar cvfz cycle.ooo.log.tgz cycle.ooo.log --remove-files
	mv o3_trace.out o3_trace.outoforder.out

debug: test.sift
	$(SNIPER_ROOT)/run-sniper -v -c $(SNIPER_ROOT)/config/riscv-mediumboom.cfg --traces=test.sift --gdb

debug_cui: test.sift
	$(SNIPER_ROOT)/run-sniper -v -c $(SNIPER_ROOT)/config/riscv-mediumboom.cfg --traces=test.sift --gdb --gdb-wait

run-io: test.sift # Inorder Implementation
	$(SNIPER_ROOT)/run-sniper -v -c $(SNIPER_ROOT)/config/riscv-inorderboom.cfg --traces=test.sift > cycle.io.log 2>&1
	grep rdcycle -B2 cycle.io.log | grep Running | awk '{ if(NR%2==1) { start=$$3 } else { print $$3-start} }' > cycle.io
	tar cvfz cycle.io.log.tgz cycle.io.log --remove-files
	mv o3_trace.out o3_trace.inorder.out

run-vio: test.sift # Vector Inorder Implementation
	$(SNIPER_ROOT)/run-sniper -v -c $(SNIPER_ROOT)/config/riscv-vinorderboom.cfg --traces=test.sift > cycle.vio.log 2>&1
	grep rdcycle -B2 cycle.vio.log | grep Running | awk '{ if(NR%2==1) { start=$$3 } else { print $$3-start} }' > cycle.vio
	tar cvfz cycle.vio.log.tgz cycle.vio.log --remove-files
	mv o3_trace.out o3_trace.vinorder.out

test.sift : test.elf
	$(SPIKE) -l --isa=rv64gcv --log-commits --sift $@ $(PK) test.elf > test.spike.log 2>&1
	hexdump -C $@ > $@.hex
	$(SNIPER_ROOT)/sift/siftdump $@ > $@.dmp 2>&1

test.elf: $(SOURCE_FILES)
	riscv64-unknown-elf-gcc -march=rv64gv -O3 $^ -o $@  -I../../sniper/include -I../common/
	riscv64-unknown-elf-objdump -D $@ > $@.dmp

clean:
	$(RM) -rf test.elf.dmp test.elf *.log *.out *.info *.sift* *.sqlite3 *.cfg *.dmp

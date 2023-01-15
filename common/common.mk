GCC_ROOT = /riscv/
SNIPER_ROOT = ../../sniper
SPIKE = $(SNIPER_ROOT)/../riscv-isa-sim/spike
PK = /riscv/riscv64-unknown-elf/bin/pk

run-ooo: test.sift
	$(SNIPER_ROOT)/run-sniper --power -v -c $(SNIPER_ROOT)/config/riscv-mediumboom.vlen$(VLEN).cfg --traces=test.sift > cycle.ooo.log 2>&1
	awk '{ if($$1 == "CycleTrace") { if (cycle==0) { cycle=$$2 } else { print $$2 - cycle; cycle=0;} }}'  cycle.ooo.log > cycle.ooo
	xz -f cycle.ooo.log
	mv o3_trace.out o3_trace.outoforder.out
	$(MAKE) sniper2mcpat DIR=.

run-io: test.sift # Inorder Implementation
	$(SNIPER_ROOT)/run-sniper --power -v -c $(SNIPER_ROOT)/config/riscv-inorderboom.vlen$(VLEN).cfg --traces=test.sift > cycle.io.log 2>&1
	awk '{ if($$1 == "CycleTrace") { if (cycle==0) { cycle=$$2 } else { print $$2 - cycle; cycle=0;} }}' cycle.io.log > cycle.io
	xz -f cycle.io.log
	mv o3_trace.out o3_trace.inorder.out

run-vio: test.sift # Vector Inorder Implementation
	$(SNIPER_ROOT)/run-sniper --power -v -c $(SNIPER_ROOT)/config/riscv-vinorderboom.vlen$(VLEN).cfg --traces=test.sift > cycle.vio.log 2>&1
	awk '{ if($$1 == "CycleTrace") { if (cycle==0) { cycle=$$2 } else { print $$2 - cycle; cycle=0;} }}' cycle.vio.log > cycle.vio
	xz -f cycle.vio.log
	mv o3_trace.out o3_trace.vinorder.out

debug: test.sift
	$(SNIPER_ROOT)/run-sniper -v -c $(SNIPER_ROOT)/config/riscv-mediumboom.vlen$(VLEN).cfg --traces=test.sift --gdb

debug_cui: test.sift
	$(SNIPER_ROOT)/run-sniper -v -c $(SNIPER_ROOT)/config/riscv-mediumboom.vlen$(VLEN).cfg --traces=test.sift --gdb --gdb-wait

debug_valgrind: test.sift
	valgrind --leak-check=full $(SNIPER_ROOT)/run-sniper -v -c $(SNIPER_ROOT)/config/riscv-mediumboom.vlen$(VLEN).cfg --traces=test.sift

test.sift : test.elf
	$(SPIKE) -l --isa=rv64gcv --varch=vlen:$(VLEN),elen:64 --log-commits --sift $@ $(PK) test.elf > test.spike.log 2>&1
	$(SNIPER_ROOT)/sift/siftdump $@ > $@.dmp 2>&1

test.elf: $(SOURCE_FILES)
	$(GCC_ROOT)/bin/riscv64-unknown-elf-gcc-12.0.1 -march=rv64gv -O3 $^ -o $@  -I../../sniper/include -I../common/
	$(GCC_ROOT)/bin/riscv64-unknown-elf-objdump -D $@ > $@.dmp

sniper2mcpat:
	python3 ../../sniper2mcpat/sniper2mcpat.py $(DIR)/sim.stats.sqlite3 ../mcpat_common/mcpat.template.vec$(VLEN).xml

clean:
	$(RM) -rf test.elf.dmp test.elf *.log *.log.tgz *.out *.info *.sift* *.sqlite3 *.cfg *.dmp
	$(RM) -rf cycle.*
	$(RM) -rf power.*
	$(RM) -rf sim.stats.*
	$(RM) -rf cfg.xml
	$(RM) -rf *.log.0

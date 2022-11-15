.PHONY : run

SOURCE_FILES = rvv_strncpy.c

include common.mk

run: test.sift
	$(SNIPER_ROOT)/run-sniper -v -c $(SNIPER_ROOT)/config/riscv.cfg --traces=test.sift > cycle.log 2>&1

debug: test.sift
	$(SNIPER_ROOT)/run-sniper -v -c $(SNIPER_ROOT)/config/riscv.cfg --traces=test.sift --gdb

debug_cui: test.sift
	$(SNIPER_ROOT)/run-sniper -v -c $(SNIPER_ROOT)/config/riscv.cfg --traces=test.sift --gdb --gdb-wait

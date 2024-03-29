SNIPER_DEBUG ?=
ifeq ($(DEBUG),on)
	SNIPER_DEBUG += --gdb-wait
endif

SNIPER_ROOT = $(realpath ../../../sniper ../../../../sniper)

rvv_target    ?= $(APP_NAME).vector
serial_target ?= $(APP_NAME).scalar

ifeq ($(MODE),ooo)
	SNIPER_CONFIG = riscv-mediumboom
	MODE = ooo
	LOG_FILE = $(basename $(notdir $(rvv_target))).$(MODE).v.v$(VLEN)_d$(DLEN)
endif # ($(MODE),ooo)
ifeq ($(MODE),vio)
	SNIPER_CONFIG = riscv-vinorderboom
	MODE = vio
	LOG_FILE = $(basename $(notdir $(rvv_target))).$(MODE).v.v$(VLEN)_d$(DLEN)
endif # ($(MODE),ooo)
ifeq ($(MODE),vio-fence)
	SNIPER_CONFIG = riscv-vino-fence
	MODE = vio-fence
	LOG_FILE = $(basename $(notdir $(rvv_target))).$(MODE).v.v$(VLEN)_d$(DLEN)
endif # ($(MODE),vio-fence)
ifeq ($(MODE),vio-ngs)
	SNIPER_CONFIG = riscv-inactive-gatherscatter
	MODE = vio-ngs
	LOG_FILE = $(basename $(notdir $(rvv_target))).$(MODE).v.v$(VLEN)_d$(DLEN)
endif # ($(MODE),vio-fence)
ifeq ($(MODE),lsu-inorder)
	SNIPER_CONFIG = riscv-mediumboom-lsuino
	MODE = vio
	LOG_FILE = $(basename $(notdir $(rvv_target))).$(MODE).v.v$(VLEN)_d$(DLEN)
endif # ($(MODE),vio-fence)
ifeq ($(MODE),ino)
	SNIPER_CONFIG = riscv-inorderboom
	MODE = ino
	LOG_FILE = $(basename $(notdir $(rvv_target))).$(MODE).v.v$(VLEN)_d$(DLEN)
endif
ifeq ($(MODE),s-ooo)
	SNIPER_CONFIG = riscv-mediumboom
	MODE = ooo
	LOG_FILE = $(basename $(notdir $(rvv_target))).$(MODE)
endif
ifeq ($(MODE),s-ino)
	SNIPER_CONFIG = riscv-inorderboom
	MODE = ino
	LOG_FILE = $(basename $(notdir $(rvv_target))).$(MODE)
endif


execute-sniper:
	$(SNIPER_ROOT)/run-sniper $(SNIPER_DEBUG) --roi \
		-v -c $(SNIPER_ROOT)/config/riscv-base.cfg \
		-c $(SNIPER_ROOT)/config/$(SNIPER_CONFIG).v$(VLEN)_d$(DLEN).cfg \
		--traces=../$(SIFT) > $(LOG_FILE).log 2>&1
	awk 'BEGIN{cycle=-1;} { if($$1 == "CycleTrace") { if (cycle==-1) { cycle=$$2 } else { print $$2 - cycle; cycle=-1;} }}' \
		$(LOG_FILE).log > cycle
	if [ -e o3_trace.out ]; then\
		mv -f o3_trace.out $(LOG_FILE).konata; gzip -f $(LOG_FILE).konata; \
	fi
	if [ -e kanata_trace.log ]; then\
		mv -f kanata_trace.log $(LOG_FILE).kanata; gzip -f $(LOG_FILE).kanata; \
	fi
	xz -f $(LOG_FILE).log

execute-sniper-s:
	$(SNIPER_ROOT)/run-sniper $(SNIPER_DEBUG) --roi \
		-v -c $(SNIPER_ROOT)/config/riscv-base.cfg \
		-c $(SNIPER_ROOT)/config/$(SNIPER_CONFIG).v128_d128.cfg \
		--traces=../$(SIFT) > $(LOG_FILE).log 2>&1
	awk 'BEGIN{cycle=-1;} { if($$1 == "CycleTrace") { if (cycle==-1) { cycle=$$2 } else { print $$2 - cycle; cycle=-1;} }}' \
		$(LOG_FILE).log > cycle
	if [ -e o3_trace.out ]; then\
		mv -f o3_trace.out $(LOG_FILE).konata; gzip -f $(LOG_FILE).konata; \
	fi
	if [ -e kanata_trace.log ]; then\
		mv -f kanata_trace.log $(LOG_FILE).kanata; gzip -f $(LOG_FILE).kanata; \
	fi
	xz -f $(LOG_FILE).log

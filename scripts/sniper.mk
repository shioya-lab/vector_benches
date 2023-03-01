SNIPER_DEBUG ?=
ifeq ($(DEBUG),on)
	SNIPER_DEBUG += --gdb-wait
endif

SNIPER_ROOT = $(realpath ../../../sniper ../../../../sniper)

rvv_target    ?= $(APP_NAME).vector
serial_target ?= $(APP_NAME).scalar

ifeq ($(MODE),ooo)
	SNIPER_CONFIG = riscv-mediumboom
else # ($(MODE),ooo)
ifeq ($(MODE),vio)
	SNIPER_CONFIG = riscv-vinorderboom
else # ($(MODE),ooo)
ifeq ($(MODE),ino)
	SNIPER_CONFIG = riscv-inorderboom
endif
endif
endif

execute-sniper:
	$(SNIPER_ROOT)/run-sniper $(SNIPER_DEBUG) --power \
		-v -c $(SNIPER_ROOT)/config/riscv-base.cfg \
		-c $(SNIPER_ROOT)/config/$(SNIPER_CONFIG).v$(VLEN)_d$(DLEN).cfg \
		--traces=../$(SIFT) > $(basename $(notdir $(rvv_target))).ooo.v.v$(VLEN)_d$(DLEN).log 2>&1
	awk 'BEGIN{cycle=-1;} { if($$1 == "CycleTrace") { if (cycle==-1) { cycle=$$2 } else { print $$2 - cycle; cycle=-1;} }}' \
		$(basename $(notdir $(rvv_target))).ooo.v.v$(VLEN)_d$(DLEN).log > cycle
	xz -f $(basename $(notdir $(rvv_target))).ooo.v.v$(VLEN)_d$(DLEN).log
	mv o3_trace.out $(APP_NAME).v$(VLEN)_d$(DLEN).ooo.out

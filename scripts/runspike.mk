LLVM = /riscv
GCC_TOOLCHAIN_DIR = /riscv
SYSROOT_DIR := $(GCC_TOOLCHAIN_DIR)/riscv64-unknown-elf

SNIPER_ROOT = $(realpath ../../../sniper ../../../../sniper)
SPIKE_ROOT  = $(realpath ../../../riscv-isa-sim ../../../../riscv-isa-sim)
SPIKE = $(SPIKE_ROOT)/spike

PK ?= $(SYSROOT_DIR)/bin/pk
# PK = $(HOME)/riscv64/riscv64-unknown-elf/bin/pk

rvv_target    ?= $(APP_NAME).vector
serial_target ?= $(APP_NAME).scalar

rvv_sift    ?= $(basename $(notdir $(rvv_target)))_v$(VLEN).sift
serial_sift ?= $(basename $(notdir $(serial_target))).sift

RUNSPIKE_MK  = $(realpath ../scripts/runspike.mk ../../scripts/runspike.mk)
SNIPER_MK    = $(realpath ../scripts/sniper.mk ../../scripts/sniper.mk)
MCPAT_MK     = $(realpath ../scripts/mcpat.mk ../../scripts/mcpat.mk)
SNIPER2MCPAT = $(realpath ../../../sniper2mcpat/sniper2mcpat.py ../../../../sniper2mcpat/sniper2mcpat.py)
MCPAT_TEMPLATE_XML = $(realpath ../../mcpat_common/mcpat.template.vec.xml    ../../../mcpat_common/mcpat.template.vec.xml    ../../../../mcpat_common/mcpat.template.vec.xml)

VLEN ?= 256
DLEN ?= $(VLEN)

ifeq ($(APP_NAME),)
	$(error "APP_NAME should be set")
endif

.PHONY: build vector scalar
.PHONY: runspike-s runspike-v
.PHONY: runsniper runsniper-v runsniper-s
.PHONY: runsniper-ooo-v runsniper-vio-v runsniper-vio-fence-v runsniper-ino-v runsniper-lsu-inorder-v
.PHONY: runsniper-ooo-s runsniper-ino-s

build:
	$(MAKE) vector scalar
	$(MAKE) runspike-s runspike-v
	$(MAKE) runsniper
	$(MAKE) runmcpat

runsniper:
	$(MAKE) runsniper-v runsniper-s
	xzgrep "cycles = " spike-s.log.xz | sed 's/cycles = //g'           | xargs echo -n >  perf_v$(VLEN)_d$(DLEN).csv; echo -n " " >> perf_v$(VLEN)_d$(DLEN).csv
	paste ino.s/cycle ooo.s/cycle                                      | xargs echo -n >> perf_v$(VLEN)_d$(DLEN).csv; echo -n " " >> perf_v$(VLEN)_d$(DLEN).csv
	xzgrep "cycles = " spike-v.$(VLEN).log.xz | sed 's/cycles = //g'   | xargs echo -n >> perf_v$(VLEN)_d$(DLEN).csv; echo -n " " >> perf_v$(VLEN)_d$(DLEN).csv
	xzgrep "vecinst = " spike-v.$(VLEN).log.xz | sed 's/vecinst = //g' | xargs echo -n >> perf_v$(VLEN)_d$(DLEN).csv; echo -n " " >> perf_v$(VLEN)_d$(DLEN).csv
	paste ino.v.v$(VLEN)_d$(DLEN)/cycle \
		  vio.v.fence.v$(VLEN)_d$(DLEN)/cycle \
		  vio.v.ngs.v$(VLEN)_d$(DLEN)/cycle \
		  vio.v.lsu-inorder.v$(VLEN)_d$(DLEN)/cycle \
		  vio.v.v$(VLEN)_d$(DLEN)/cycle \
		  ooo.v.v$(VLEN)_d$(DLEN)/cycle >> perf_v$(VLEN)_d$(DLEN).csv

runmcpat:
	$(MAKE) runmcpat-ooo-v runmcpat-ino-v runmcpat-vio-v runmcpat-vio-fence-v runmcpat-vio-ngs-v  runmcpat-lsu-inorder-v 


runsniper-v:
	$(MAKE) runsniper-ooo-v runsniper-ino-v runsniper-vio-v runsniper-lsu-inorder-v runsniper-vio-fence-v runsniper-vio-ngs-v 

runsniper-s:
	$(MAKE) runsniper-ooo-s runsniper-ino-s

power-v:
	$(MAKE) _power-ooo-v _power-vio-v _power-ino-v

power-s:
	$(MAKE) _power-ooo-s _power-ino-s


runspike-v : $(rvv_target)
	$(MAKE) $(rvv_sift)

$(rvv_sift): $(rvv_target)
	$(SPIKE) --isa=rv64gcv --varch=vlen:$(VLEN),elen:64 --sift $@ $(PK) $^ $(SPIKE_OPTS) > spike-v.$(VLEN).log 2>&1
	xz -f spike-v.$(VLEN).log

runspike-s : $(serial_target)
	$(MAKE) $(serial_sift)

$(serial_sift): $(serial_target)
	$(SPIKE) --isa=rv64gc --varch=vlen:$(VLEN),elen:64 --sift $@ $(PK) $^ $(SPIKE_OPTS) > spike-s.log 2>&1
	xz -f spike-s.log

runspike-debug-v : $(rvv_target)
	$(SPIKE) --isa=rv64gcv --varch=vlen:$(VLEN),elen:64 -l --log-commits --sift $(rvv_sift)    $(PK) $^ $(SPIKE_OPTS) > spike-v.$(VLEN).log 2>&1

runspike-debug-s : $(serial_target)
	$(SPIKE) --isa=rv64gc  -l --log-commits --sift $(serial_sift) $(PK) $^ $(SPIKE_OPTS) > spike-s.log 2>&1



runsniper-ooo-v: $(rvv_sift)
	mkdir -p ooo.v.v$(VLEN)_d$(DLEN)
	$(MAKE) execute-sniper      -C ooo.v.v$(VLEN)_d$(DLEN) -f $(SNIPER_MK) VLEN=$(VLEN) DLEN=$(DLEN) MODE=ooo APP_NAME=$(APP_NAME) SIFT=$(rvv_sift)

runmcpat-ooo-v:
	mkdir -p ooo.v.v$(VLEN)_d$(DLEN)
	$(MAKE) execute-mcpat-ooo-v -C ooo.v.v$(VLEN)_d$(DLEN) -f $(MCPAT_MK)  VLEN=$(VLEN) DLEN=$(DLEN) APP_NAME=$(APP_NAME)

runsniper-ino-v: $(rvv_sift)
	mkdir -p ino.v.v$(VLEN)_d$(DLEN)
	$(MAKE) execute-sniper      -C ino.v.v$(VLEN)_d$(DLEN) -f $(SNIPER_MK) VLEN=$(VLEN) DLEN=$(DLEN) MODE=ino APP_NAME=$(APP_NAME) SIFT=$(rvv_sift)

runmcpat-ino-v:
	mkdir -p ino.v.v$(VLEN)_d$(DLEN)
	$(MAKE) execute-mcpat-ino-v -C ino.v.v$(VLEN)_d$(DLEN) -f $(MCPAT_MK)  VLEN=$(VLEN) DLEN=$(DLEN) APP_NAME=$(APP_NAME)

runsniper-vio-v: $(rvv_sift)
	mkdir -p vio.v.v$(VLEN)_d$(DLEN)
	$(MAKE) execute-sniper      -C vio.v.v$(VLEN)_d$(DLEN) -f $(SNIPER_MK) VLEN=$(VLEN) DLEN=$(DLEN) MODE=vio APP_NAME=$(APP_NAME) SIFT=$(rvv_sift)

runmcpat-vio-v:
	mkdir -p vio.v.v$(VLEN)_d$(DLEN)
	$(MAKE) execute-mcpat-vio-v -C vio.v.v$(VLEN)_d$(DLEN) -f $(MCPAT_MK)  VLEN=$(VLEN) DLEN=$(DLEN) APP_NAME=$(APP_NAME)

# Vector to Scalar, Insert InOrder
runsniper-vio-fence-v: $(rvv_sift)
	mkdir -p vio.v.fence.v$(VLEN)_d$(DLEN)
	$(MAKE) execute-sniper      -C vio.v.fence.v$(VLEN)_d$(DLEN) -f $(SNIPER_MK) VLEN=$(VLEN) DLEN=$(DLEN) MODE=vio-fence APP_NAME=$(APP_NAME) SIFT=$(rvv_sift)

runmcpat-vio-fence-v: $(rvv_sift)
	mkdir -p vio.v.fence.v$(VLEN)_d$(DLEN)
	$(MAKE) execute-mcpat-vio-fence-v -C vio.v.fence.v$(VLEN)_d$(DLEN) -f $(MCPAT_MK)  VLEN=$(VLEN) DLEN=$(DLEN) APP_NAME=$(APP_NAME)

# Non-Gather-Scatter Merge
runsniper-vio-ngs-v: $(rvv_sift)
	mkdir -p vio.v.ngs.v$(VLEN)_d$(DLEN)
	$(MAKE) execute-sniper      -C vio.v.ngs.v$(VLEN)_d$(DLEN) -f $(SNIPER_MK) VLEN=$(VLEN) DLEN=$(DLEN) MODE=vio-ngs APP_NAME=$(APP_NAME) SIFT=$(rvv_sift)

runmcpat-vio-ngs-v: $(rvv_sift)
	mkdir -p vio.v.ngs.v$(VLEN)_d$(DLEN)
	$(MAKE) execute-mcpat-vio-ngs-v -C vio.v.ngs.v$(VLEN)_d$(DLEN) -f $(MCPAT_MK)  VLEN=$(VLEN) DLEN=$(DLEN) APP_NAME=$(APP_NAME)

# Only LSU Inorder
runsniper-lsu-inorder-v: $(rvv_sift)
	mkdir -p vio.v.lsu-inorder.v$(VLEN)_d$(DLEN)
	$(MAKE) execute-sniper      -C vio.v.lsu-inorder.v$(VLEN)_d$(DLEN) -f $(SNIPER_MK) VLEN=$(VLEN) DLEN=$(DLEN) MODE=lsu-inorder APP_NAME=$(APP_NAME) SIFT=$(rvv_sift)

runmcpat-lsu-inorder-v: $(rvv_sift)
	mkdir -p vio.v.ngs.v$(VLEN)_d$(DLEN)
	$(MAKE) execute-mcpat-lsu-inorder-v -C vio.v.lsu-inorder.v$(VLEN)_d$(DLEN) -f $(MCPAT_MK)  VLEN=$(VLEN) DLEN=$(DLEN) APP_NAME=$(APP_NAME)

runsniper-ooo-s: $(serial_sift)
	mkdir -p ooo.s
	$(MAKE) execute-sniper-s -C ooo.s -f $(SNIPER_MK) MODE=s-ooo APP_NAME=$(APP_NAME) SIFT=$(serial_sift)

runmcpat-ooo-s: $(serial_sift)
	mkdir -p ooo.s
	$(MAKE) execute-mcpat-ooo-s -C ooo.s -f $(MCPAT_MK) APP_NAME=$(APP_NAME)


runsniper-ino-s: $(serial_sift)
	mkdir -p ino.s
	$(MAKE) execute-sniper-s   -C ino.s -f $(SNIPER_MK) MODE=s-ino APP_NAME=$(APP_NAME) SIFT=$(serial_sift)

runmcpat-ino-s: $(serial_sift)
	mkdir -p ino.s
	$(MAKE) execute-mcpat-ino-s -C ino.s -f $(MCPAT_MK) APP_NAME=$(APP_NAME)

_power-ooo-v:
	$(MAKE) -f $(RUNSPIKE_MK) sniper2mcpat APP_NAME=$(APP_NAME) VLEN=$(VLEN) DLEN=$(DLEN) -C ooo.v.v$(VLEN)_d$(DLEN)
_power-vio-v:
	$(MAKE) -f $(RUNSPIKE_MK) sniper2mcpat APP_NAME=$(APP_NAME) VLEN=$(VLEN) DLEN=$(DLEN) -C vio.v.v$(VLEN)_d$(DLEN)
_power-ino-v:
	$(MAKE) -f $(RUNSPIKE_MK) sniper2mcpat APP_NAME=$(APP_NAME) VLEN=$(VLEN) DLEN=$(DLEN) -C ino.v.v$(VLEN)_d$(DLEN)
_power-ooo-s:
	$(MAKE) -f $(RUNSPIKE_MK) sniper2mcpat APP_NAME=$(APP_NAME) VLEN=$(VLEN) DLEN=$(DLEN) -C ooo.s
_power-ino-s:
	$(MAKE) -f $(RUNSPIKE_MK) sniper2mcpat APP_NAME=$(APP_NAME) VLEN=$(VLEN) DLEN=$(DLEN) -C ino.s


sniper2mcpat:
	python3 $(SNIPER2MCPAT) sim.stats.sqlite3 $(MCPAT_TEMPLATE_XML)

clean:
	rm -rf $(rvv_target) $(serial_target)
	rm -rf output.txt
	rm -rf ino.s
	rm -rf ooo.s
	rm -rf ino.v.*
	rm -rf ooo.v.*
	rm -rf vio.v.*
	rm -rf *.sift
	rm -rf *.log
	rm -rf bin/*
	rm -rf *.xz
	rm -rf *.dmp

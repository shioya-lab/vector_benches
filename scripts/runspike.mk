LLVM = /riscv
GCC_TOOLCHAIN_DIR = /riscv
SYSROOT_DIR := $(GCC_TOOLCHAIN_DIR)/riscv64-unknown-elf

SNIPER_ROOT = $(realpath ../../sniper ../../../sniper)
SPIKE = $(SNIPER_ROOT)/../riscv-isa-sim/spike
PK ?= $(SYSROOT_DIR)/bin/pk
# PK = $(HOME)/riscv64/riscv64-unknown-elf/bin/pk

rvv_target    ?= $(APP_NAME).vector
serial_target ?= $(APP_NAME).scalar

rvv_sift    ?= $(basename $(notdir $(rvv_target))).sift
serial_sift ?= $(basename $(notdir $(serial_target))).sift

RUNSPIKE_MK  = $(realpath ../scripts/runspike.mk ../../scripts/runspike.mk)
SNIPER2MCPAT = $(realpath ../../../sniper2mcpat/sniper2mcpat.py ../../../../sniper2mcpat/sniper2mcpat.py)
CFG_INO_XML  = $(realpath ../../mcpat_common/cfg.$(VLEN).ino.xml ../../../mcpat_common/cfg.$(VLEN).ino.xml ../../../../mcpat_common/cfg.$(VLEN).ino.xml)
CFG_VIO_XML  = $(realpath ../../mcpat_common/cfg.$(VLEN).vio.xml ../../../mcpat_common/cfg.$(VLEN).vio.xml ../../../../mcpat_common/cfg.$(VLEN).vio.xml)
CFG_VEC_OOO_XML  = $(realpath ../../mcpat_common/cfg.vec$(VLEN).ooo.xml ../../../mcpat_common/cfg.vec$(VLEN).ooo.xml ../../../../mcpat_common/cfg.vec$(VLEN).ooo.xml)
CFG_VEC_INO_XML  = $(realpath ../../mcpat_common/cfg.vec$(VLEN).ino.xml ../../../mcpat_common/cfg.vec$(VLEN).ino.xml ../../../../mcpat_common/cfg.vec$(VLEN).ino.xml)
CFG_SCALAR_OOO_XML  = $(realpath ../../mcpat_common/cfg.scalar.ooo.xml ../../../mcpat_common/cfg.scalar.ooo.xml ../../../../mcpat_common/cfg.scalar.ooo.xml)
CFG_SCALAR_INO_XML  = $(realpath ../../mcpat_common/cfg.scalar.ino.xml ../../../mcpat_common/cfg.scalar.ino.xml ../../../../mcpat_common/cfg.scalar.ino.xml)
CFG_SCALAR_TO_VEC_OOO_XML  = $(realpath ../../mcpat_common/cfg.scalar_to_vec.xml ../../../mcpat_common/cfg.scalar_to_vec.xml ../../../../mcpat_common/cfg.scalar_to_vec.xml)
CFG_SCALAR_TO_VEC_INO_XML  = $(realpath ../../mcpat_common/cfg.scalar_to_vec.ino.xml ../../../mcpat_common/cfg.scalar_to_vec.ino.xml ../../../../mcpat_common/cfg.scalar_to_vec.ino.xml)
CFG_VEC_TO_SCALAR_XML  = $(realpath ../../mcpat_common/cfg.vec_to_scalar.xml ../../../mcpat_common/cfg.vec_to_scalar.xml ../../../../mcpat_common/cfg.vec_to_scalar.xml)

MCPAT_TEMPLATE_XML = $(realpath ../../../mcpat_common/mcpat.template.vec.xml ../../mcpat_common/mcpat.template.vec.xml)

VLEN ?= 256
DLEN ?= $(VLEN)

ifeq ($(APP_NAME),)
	$(error "APP_NAME should be set")
endif

SNIPER_DEBUG ?=
ifeq ($(DEBUG),on)
	SNIPER_DEBUG += --gdb-wait
endif

.PHONY: build vector scalar
.PHONY: runspike-s runspike-v
.PHONY: runsniper runsniper-v runsniper-s
.PHONY: runsniper-ooo-v runsniper-vio-v runsniper-ino-v
.PHONY: runsniper-ooo-s runsniper-ino-s

build:
	$(MAKE) vector scalar
	$(MAKE) runspike-s runspike-v
	$(MAKE) runsniper

runsniper:
	$(MAKE) runsniper-v runsniper-s

power: _power-ooo-v _power-vio-v _power-ino-v
	echo -n "Application," > power.$(VLEN).filtered.csv
	head -n1 ooo.v.$(VLEN)/sim.stats.mcpat.output.filtered.csv >> power.$(VLEN).filtered.csv
	if [ -d ino.s ]; then \
		$(MAKE) _power-ino-s; \
		echo -n $(APP_NAME)_ino_s_$(VLEN)"," >> power.$(VLEN).filtered.csv; tail -n+2 ino.s/sim.stats.mcpat.output.filtered.csv         >> power.$(VLEN).filtered.csv; \
	fi
	if [ -d ooo.s ]; then \
		$(MAKE) _power-ooo-s; \
		echo -n $(APP_NAME)_ooo_s_$(VLEN)"," >> power.$(VLEN).filtered.csv; tail -n+2 ooo.s/sim.stats.mcpat.output.filtered.csv         >> power.$(VLEN).filtered.csv; \
	fi
	echo -n $(APP_NAME)_ino_v_$(VLEN)"," >> power.$(VLEN).filtered.csv; tail -n+2 ino.v.$(VLEN)/sim.stats.mcpat.output.filtered.csv >> power.$(VLEN).filtered.csv
	echo -n $(APP_NAME)_vio_v_$(VLEN)"," >> power.$(VLEN).filtered.csv; tail -n+2 vio.v.$(VLEN)/sim.stats.mcpat.output.filtered.csv >> power.$(VLEN).filtered.csv
	echo -n $(APP_NAME)_ooo_v_$(VLEN)"," >> power.$(VLEN).filtered.csv; tail -n+2 ooo.v.$(VLEN)/sim.stats.mcpat.output.filtered.csv >> power.$(VLEN).filtered.csv


runsniper-v:
	$(MAKE) runsniper-ooo-v runsniper-vio-v runsniper-ino-v

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
	mkdir -p ooo.v.v$(VLEN)_d$(DLEN) && \
	cd ooo.v.v$(VLEN)_d$(DLEN) && \
	$(SNIPER_ROOT)/run-sniper $(SNIPER_DEBUG) --power -v -c $(SNIPER_ROOT)/config/riscv-base.cfg -c $(SNIPER_ROOT)/config/riscv-mediumboom.v$(VLEN)_d$(DLEN).cfg --traces=../$^ > $(basename $(notdir $(rvv_target))).ooo.v.v$(VLEN)_d$(DLEN).log 2>&1 && \
	awk 'BEGIN{cycle=-1;} { if($$1 == "CycleTrace") { if (cycle==-1) { cycle=$$2 } else { print $$2 - cycle; cycle=-1;} }}'  $(basename $(notdir $(rvv_target))).ooo.v.v$(VLEN)_d$(DLEN).log > cycle && \
	xz -f $(basename $(notdir $(rvv_target))).ooo.v.v$(VLEN)_d$(DLEN).log && \
	mv o3_trace.out $(APP_NAME).v$(VLEN)_d$(DLEN).ooo.out && \
	ln -sf $(CFG_SCALAR_OOO_XML) cfg.xml && \
	python3 $(SNIPER2MCPAT) sim.stats.sqlite3 $(MCPAT_TEMPLATE_XML) scalar_ooo && \
	mv sim.stats.mcpat.input.xml cfg.scalar.input.xml && \
	mv sim.stats.mcpat.output.txt cfg.scalar.output.txt && \
	tr -d '\r' < sim.stats.mcpat.output.filtered.csv > cfg.scalar.csv && \
	ln -sf $(CFG_VEC_OOO_XML) cfg.xml && \
	python3 $(SNIPER2MCPAT) sim.stats.sqlite3 $(MCPAT_TEMPLATE_XML) vec && \
	mv sim.stats.mcpat.input.xml cfg.vec128.ooo.input.xml && \
	tr -d '\r' < sim.stats.mcpat.output.filtered.csv > cfg.vec128.ooo.csv && \
	ln -sf $(CFG_SCALAR_TO_VEC_OOO_XML) cfg.xml && \
	python3 $(SNIPER2MCPAT) sim.stats.sqlite3 $(MCPAT_TEMPLATE_XML) scalar_to_vec && \
	mv sim.stats.mcpat.input.xml cfg.scalar_to_vec.input.xml && \
	tr -d '\r' < sim.stats.mcpat.output.filtered.csv > cfg.scalar_to_vec.csv && \
	ln -sf $(CFG_VEC_TO_SCALAR_XML) cfg.xml && \
	python3 $(SNIPER2MCPAT) sim.stats.sqlite3 $(MCPAT_TEMPLATE_XML) vec_to_scalar && \
	mv sim.stats.mcpat.input.xml cfg.vec_to_scalar.input.xml && \
	tr -d '\r' < sim.stats.mcpat.output.filtered.csv > cfg.vec_to_scalar.csv && \
	paste -d',' cfg.scalar.csv cfg.vec128.ooo.csv  cfg.vec_to_scalar.csv cfg.scalar_to_vec.csv | sed 's/,sim.stats.mcpat.output.txt//g' | sed 's/^sim.stats.mcpat.output.txt/$(APP_NAME)-OoO/g' > power.csv

runsniper-ino-v: $(rvv_sift)
	mkdir -p ino.v.v$(VLEN)_d$(DLEN) && \
	cd ino.v.v$(VLEN)_d$(DLEN) && \
	$(SNIPER_ROOT)/run-sniper $(SNIPER_DEBUG) --power -v -c $(SNIPER_ROOT)/config/riscv-base.cfg -c $(SNIPER_ROOT)/config/riscv-inorderboom.v$(VLEN)_d$(DLEN).cfg --traces=../$^ > $(basename $(notdir $(rvv_target))).ino.v.v$(VLEN)_d$(DLEN).log 2>&1 && \
	awk 'BEGIN{cycle=-1;} { if($$1 == "CycleTrace") { if (cycle==-1) { cycle=$$2 } else { print $$2 - cycle; cycle=-1;} }}'  $(basename $(notdir $(rvv_target))).ino.v.v$(VLEN)_d$(DLEN).log > cycle && \
	xz -f $(basename $(notdir $(rvv_target))).ino.v.v$(VLEN)_d$(DLEN).log && \
	mv o3_trace.out $(APP_NAME).v$(VLEN)_d$(DLEN).ino.out && \
	ln -sf $(CFG_SCALAR_INO_XML) cfg.xml && \
	python3 $(SNIPER2MCPAT) sim.stats.sqlite3 $(MCPAT_TEMPLATE_XML) scalar_ooo && \
	mv sim.stats.mcpat.input.xml cfg.scalar.input.xml && \
	mv sim.stats.mcpat.output.txt cfg.scalar.output.txt && \
	tr -d '\r' < sim.stats.mcpat.output.filtered.csv > cfg.scalar.csv && \
	ln -sf $(CFG_VEC_INO_XML) cfg.xml && \
	python3 $(SNIPER2MCPAT) sim.stats.sqlite3 $(MCPAT_TEMPLATE_XML) vec && \
	mv sim.stats.mcpat.input.xml cfg.vec128.ino.input.xml && \
	mv sim.stats.mcpat.output.txt cfg.vec128.ino.output.txt && \
	tr -d '\r' < sim.stats.mcpat.output.filtered.csv > cfg.vec128.ino.csv && \
	paste -d',' cfg.scalar.csv cfg.vec128.ino.csv | sed 's/,sim.stats.mcpat.output.txt//g' | sed 's/^sim.stats.mcpat.output.txt/$(APP_NAME)-InO/g' > power.csv

runsniper-vio-v: $(rvv_sift)
	mkdir -p vio.v.v$(VLEN)_d$(DLEN) && \
	cd vio.v.v$(VLEN)_d$(DLEN) && \
	$(SNIPER_ROOT)/run-sniper $(SNIPER_DEBUG) --power -v -c $(SNIPER_ROOT)/config/riscv-base.cfg -c $(SNIPER_ROOT)/config/riscv-vinorderboom.v$(VLEN)_d$(DLEN).cfg --traces=../$^ > $(basename $(notdir $(rvv_target))).vio.log 2>&1 && \
	awk 'BEGIN{cycle=-1;} { if($$1 == "CycleTrace") { if (cycle==-1) { cycle=$$2 } else { print $$2 - cycle; cycle=-1;} }}'  $(basename $(notdir $(rvv_target))).vio.log > cycle && \
	xz -f $(basename $(notdir $(rvv_target))).vio.log && \
	mv o3_trace.out $(APP_NAME).v$(VLEN)_d$(DLEN).vio.out && \
	ln -sf $(CFG_SCALAR_OOO_XML) cfg.xml && \
	python3 $(SNIPER2MCPAT) sim.stats.sqlite3 $(MCPAT_TEMPLATE_XML) scalar_ooo && \
	mv sim.stats.mcpat.input.xml cfg.scalar.input.xml && \
	mv sim.stats.mcpat.output.txt cfg.scalar.output.txt && \
	tr -d '\r' < sim.stats.mcpat.output.filtered.csv > cfg.scalar.csv && \
	ln -sf $(CFG_VEC_INO_XML) cfg.xml && \
	python3 $(SNIPER2MCPAT) sim.stats.sqlite3 $(MCPAT_TEMPLATE_XML) vec && \
	mv sim.stats.mcpat.input.xml cfg.vec128.ino.input.xml && \
	tr -d '\r' < sim.stats.mcpat.output.filtered.csv > cfg.vec128.ino.csv && \
	ln -sf $(CFG_SCALAR_TO_VEC_INO_XML) cfg.xml && \
	python3 $(SNIPER2MCPAT) sim.stats.sqlite3 $(MCPAT_TEMPLATE_XML) scalar_to_vec && \
	mv sim.stats.mcpat.input.xml cfg.scalar_to_vec.input.xml && \
	tr -d '\r' < sim.stats.mcpat.output.filtered.csv > cfg.scalar_to_vec.csv && \
	ln -sf $(CFG_VEC_TO_SCALAR_XML) cfg.xml && \
	python3 $(SNIPER2MCPAT) sim.stats.sqlite3 $(MCPAT_TEMPLATE_XML) vec_to_scalar && \
	mv sim.stats.mcpat.input.xml cfg.vec_to_scalar.input.xml && \
	tr -d '\r' < sim.stats.mcpat.output.filtered.csv > cfg.vec_to_scalar.csv && \
	paste -d',' cfg.scalar.csv cfg.vec128.ino.csv  cfg.vec_to_scalar.csv cfg.scalar_to_vec.csv | sed 's/,sim.stats.mcpat.output.txt//g' | sed 's/^sim.stats.mcpat.output.txt/$(APP_NAME)-VIO/g' > power.csv

# Non-Gather-Scatter Merge
runsniper-vio-ngs-v: $(rvv_sift)
	mkdir -p vio.v.ngs.v$(VLEN)_d$(DLEN) && \
	cd vio.v.ngs.v$(VLEN)_d$(DLEN) && \
	$(SNIPER_ROOT)/run-sniper $(SNIPER_DEBUG) --power -v -c $(SNIPER_ROOT)/config/riscv-base.cfg -c $(SNIPER_ROOT)/config/riscv-inactive-gatherscatter.v$(VLEN)_d$(DLEN).cfg --traces=../$^ > $(basename $(notdir $(rvv_target))).vio.ngs.log 2>&1 && \
	awk 'BEGIN{cycle=-1;} { if($$1 == "CycleTrace") { if (cycle==-1) { cycle=$$2 } else { print $$2 - cycle; cycle=-1;} }}'  $(basename $(notdir $(rvv_target))).vio.ngs.log > cycle && \
	xz -f $(basename $(notdir $(rvv_target))).vio.ngs.log && \
	mv o3_trace.out $(APP_NAME).v$(VLEN)_d$(DLEN).vio.ngs.out && \
	ln -sf $(CFG_SCALAR_OOO_XML) cfg.xml && \
	python3 $(SNIPER2MCPAT) sim.stats.sqlite3 $(MCPAT_TEMPLATE_XML) scalar_ooo && \
	mv sim.stats.mcpat.input.xml cfg.scalar.input.xml && \
	tr -d '\r' < sim.stats.mcpat.output.filtered.csv > cfg.scalar.csv && \
	ln -sf $(CFG_VEC_INO_XML) cfg.xml && \
	python3 $(SNIPER2MCPAT) sim.stats.sqlite3 $(MCPAT_TEMPLATE_XML) vec && \
	mv sim.stats.mcpat.input.xml cfg.vec128.ino.input.xml && \
	tr -d '\r' < sim.stats.mcpat.output.filtered.csv > cfg.vec128.ino.csv && \
	ln -sf $(CFG_SCALAR_TO_VEC_INO_XML) cfg.xml && \
	python3 $(SNIPER2MCPAT) sim.stats.sqlite3 $(MCPAT_TEMPLATE_XML) scalar_to_vec && \
	mv sim.stats.mcpat.input.xml cfg.scalar_to_vec.input.xml && \
	tr -d '\r' < sim.stats.mcpat.output.filtered.csv > cfg.scalar_to_vec.csv && \
	ln -sf $(CFG_VEC_TO_SCALAR_XML) cfg.xml && \
	python3 $(SNIPER2MCPAT) sim.stats.sqlite3 $(MCPAT_TEMPLATE_XML) vec_to_scalar && \
	mv sim.stats.mcpat.input.xml cfg.vec_to_scalar.input.xml && \
	tr -d '\r' < sim.stats.mcpat.output.filtered.csv > cfg.vec_to_scalar.csv && \
	paste -d',' cfg.scalar.csv cfg.vec128.ino.csv  cfg.vec_to_scalar.csv cfg.scalar_to_vec.csv | sed 's/,sim.stats.mcpat.output.txt//g' | sed 's/^sim.stats.mcpat.output.txt/$(APP_NAME)-VIO/g' > power.csv


runsniper-ooo-s: $(serial_sift)
	mkdir -p ooo.s && \
	cd ooo.s && \
	$(SNIPER_ROOT)/run-sniper $(SNIPER_DEBUG) --power -v -c $(SNIPER_ROOT)/config/riscv-base.cfg -c $(SNIPER_ROOT)/config/riscv-mediumboom.v$(VLEN)_d$(DLEN).cfg --traces=../$^ > $(basename $(notdir $(serial_target))).ooo.s.log 2>&1 && \
	awk 'BEGIN{cycle=-1;} { if($$1 == "CycleTrace") { if (cycle==-1) { cycle=$$2 } else { print $$2 - cycle; cycle=-1;} }}'  $(basename $(notdir $(serial_target))).ooo.s.log > cycle && \
	xz -f $(basename $(notdir $(serial_target))).ooo.s.log && \
	mv o3_trace.out $(APP_NAME).v$(VLEN)_d$(DLEN).ooo.s.out && \
	ln -sf $(CFG_SCALAR_OOO_XML) cfg.xml && \
	python3 $(SNIPER2MCPAT) sim.stats.sqlite3 $(MCPAT_TEMPLATE_XML) scalar_ooo && \
	mv sim.stats.mcpat.input.xml cfg.scalar.input.xml && \
	tr -d '\r' < sim.stats.mcpat.output.filtered.csv > cfg.scalar.csv && \
	paste -d',' cfg.scalar.csv | sed 's/,sim.stats.mcpat.output.txt//g' | sed 's/^sim.stats.mcpat.output.txt/$(APP_NAME)-VIO/g' > power.csv

runsniper-ino-s: $(serial_sift)
	mkdir -p ino.s && \
	cd ino.s && \
	$(SNIPER_ROOT)/run-sniper $(SNIPER_DEBUG) --power -v -c $(SNIPER_ROOT)/config/riscv-base.cfg -c $(SNIPER_ROOT)/config/riscv-inorderboom.v$(VLEN)_d$(DLEN).cfg --traces=../$^ > $(basename $(notdir $(serial_target))).ino.s.log 2>&1 && \
	awk 'BEGIN{cycle=-1;} { if($$1 == "CycleTrace") { if (cycle==-1) { cycle=$$2 } else { print $$2 - cycle; cycle=-1;} }}'  $(basename $(notdir $(serial_target))).ino.s.log > cycle && \
	xz -f $(basename $(notdir $(serial_target))).ino.s.log && \
	mv o3_trace.out $(APP_NAME).v$(VLEN)_d$(DLEN).ino.s.out && \
	ln -sf $(CFG_SCALAR_INO_XML) cfg.xml && \
	python3 $(SNIPER2MCPAT) sim.stats.sqlite3 $(MCPAT_TEMPLATE_XML) scalar_ooo && \
	mv sim.stats.mcpat.input.xml cfg.scalar.input.xml && \
	tr -d '\r' < sim.stats.mcpat.output.filtered.csv > cfg.scalar.csv && \
	paste -d',' cfg.scalar.csv | sed 's/,sim.stats.mcpat.output.txt//g' | sed 's/^sim.stats.mcpat.output.txt/$(APP_NAME)-VIO/g' > power.csv

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

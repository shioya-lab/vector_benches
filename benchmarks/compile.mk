#=======================================================================
# UCB VLSI FLOW: Makefile for riscv-bmarks
#-----------------------------------------------------------------------
# Yunsup Lee (yunsup@cs.berkeley.edu)
#

XLEN ?= 64

default: all

src_dir = .

instname = riscv-bmarks
instbasedir = $(UCB_VLSI_HOME)/install

#--------------------------------------------------------------------
# Sources
#--------------------------------------------------------------------

bmarks = \
	median \
	qsort \
	rsort \
	towers \
	vvadd \
	multiply \
	dhrystone \
	pmp \
	mm \
	spmv \
	mt-vvadd \
	mt-matmul \

#--------------------------------------------------------------------
# Build rules
#--------------------------------------------------------------------

RISCV_PREFIX ?= riscv$(XLEN)-unknown-elf-
RISCV_GCC ?= clang-15
RISCV_GCC_VEC_OPTS ?= \
	-O2 \
	--target=riscv64-unknown-elf -march=rv64gcv \
	--sysroot=/home/kimura/riscv64/riscv64-unknown-elf \
	--gcc-toolchain=/home/kimura/riscv64/ \
	-menable-experimental-extensions -mllvm --riscv-v-vector-bits-min=128 \
	-DPREALLOCATE=1 -mcmodel=medany \
	-DUSE_RISCV_VECTOR \
	-ffast-math -fno-common -fno-builtin-printf


RISCV_GCC_SCALAR_OPTS ?= \
	-O2 \
	--target=riscv64-unknown-elf -march=rv64gc \
	--sysroot=/home/kimura/riscv64/riscv64-unknown-elf \
	--gcc-toolchain=/home/kimura/riscv64/ \
	-DPREALLOCATE=1 -mcmodel=medany \
	-ffast-math -fno-common -fno-builtin-printf

RISCV_LINK ?= $(RISCV_GCC) -T ../common/test.ld $(incs)
RISCV_LINK_OPTS ?= -static -nostdlib -nostartfiles -lm -lgcc -T ../common/test.ld
RISCV_OBJDUMP ?= $(RISCV_PREFIX)objdump -D
RISCV_SIM ?= spike --isa=rv$(XLEN)gc

incs  += -I../env -I../common $(addprefix -I$(src_dir)/, $(bmarks))
objs  :=

define compile_template
$(1).riscv: $(wildcard $(src_dir)/$(1)/*) $(wildcard $(src_dir)/common/*)
	$$(RISCV_GCC) $$(incs) $$(RISCV_GCC_OPTS) -o $$@ $(wildcard $(src_dir)/$(1)/*.c) $(wildcard $(src_dir)/common/*.c) $(wildcard $(src_dir)/common/*.S) $$(RISCV_LINK_OPTS)
endef

# $(foreach bmark,$(bmarks),$(eval $(call compile_template,$(bmark))))

vector: $(rvv_target)
$(rvv_target):
	$(RISCV_GCC) $(incs) $(RISCV_GCC_VEC_OPTS) -o $@ $(wildcard *.c) ../common/syscalls_vector.c ../common/crt.S $(RISCV_LINK_OPTS)
#	$(RISCV_GCC) $(incs) $(RISCV_GCC_VEC_OPTS) -o $@ $(wildcard *.c) $(RISCV_LINK_OPTS)
	$(RISCV_OBJDUMP) $@ > $@.dmp

scalar: $(serial_target)
$(serial_target):
	$(RISCV_GCC) $(incs) $(RISCV_GCC_SCALAR_OPTS) -o $@ $(wildcard *.c) ../common/syscalls.c ../common/crt.S $(RISCV_LINK_OPTS)
#	$(RISCV_GCC) $(incs) $(RISCV_GCC_SCALAR_OPTS) -o $@ $(wildcard *.c) $(RISCV_LINK_OPTS)
	$(RISCV_OBJDUMP) $@ > $@.dmp

#------------------------------------------------------------
# Build and run benchmarks on riscv simulator

bmarks_riscv_bin  = $(addsuffix .riscv,  $(bmarks))
bmarks_riscv_dump = $(addsuffix .riscv.dump, $(bmarks))
bmarks_riscv_out  = $(addsuffix .riscv.out,  $(bmarks))

$(bmarks_riscv_dump): %.riscv.dump: %.riscv
	$(RISCV_OBJDUMP) $< > $@

$(bmarks_riscv_out): %.riscv.out: %.riscv
	$(RISCV_SIM) $< > $@

riscv: $(bmarks_riscv_dump)
run: $(bmarks_riscv_out)

junk += $(bmarks_riscv_bin) $(bmarks_riscv_dump) $(bmarks_riscv_hex) $(bmarks_riscv_out)

#------------------------------------------------------------
# Default

all: riscv
	$(MAKE) $(bmarks)

#------------------------------------------------------------
# Install

date_suffix = $(shell date +%Y-%m-%d_%H-%M)
install_dir = $(instbasedir)/$(instname)-$(date_suffix)
latest_install = $(shell ls -1 -d $(instbasedir)/$(instname)* | tail -n 1)

install:
	mkdir $(install_dir)
	cp -r $(bmarks_riscv_bin) $(bmarks_riscv_dump) $(install_dir)

install-link:
	rm -rf $(instbasedir)/$(instname)
	ln -s $(latest_install) $(instbasedir)/$(instname)


#------------------------------------------------------------
# Clean up

# clean:
# 	rm -rf $(objs) $(junk)

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

rvv_target    ?= $(APP_NAME).vector
serial_target ?= $(APP_NAME).scalar

#--------------------------------------------------------------------
# Build rules
#--------------------------------------------------------------------

RISCV_PREFIX ?= riscv$(XLEN)-unknown-elf-
RISCV_GCC ?= clang-16
RISCV_GCC_VEC_OPTS ?= \
	-O2 \
	-I/work/sniper/sniper/sniper/include/ \
	--target=riscv64-unknown-elf -march=rv64gv \
	--sysroot=/home/kimura/riscv64/riscv64-unknown-elf \
	--gcc-toolchain=/home/kimura/riscv64/ \
	-menable-experimental-extensions -mllvm --riscv-v-vector-bits-min=128 \
	-DPREALLOCATE=1 -mcmodel=medany \
	-DUSE_RISCV_VECTOR \
	-ffast-math -fno-common -fno-builtin-printf


RISCV_GCC_SCALAR_OPTS ?= \
	-O2 \
	-I/work/sniper/sniper/sniper/include/ \
	--target=riscv64-unknown-elf -march=rv64g \
	--sysroot=/home/kimura/riscv64/riscv64-unknown-elf \
	--gcc-toolchain=/home/kimura/riscv64/ \
	-DPREALLOCATE=1 -mcmodel=medany \
	-ffast-math -fno-common -fno-builtin-printf

RISCV_LINK ?= $(RISCV_GCC) -T ../common/test.ld $(incs)
RISCV_LINK_OPTS ?= -static -nostdlib -nostartfiles -lm -lgcc -T ../../common/test.ld
RISCV_OBJDUMP ?= $(RISCV_PREFIX)objdump -D
RISCV_SIM ?= spike --isa=rv$(XLEN)gc

incs  += -I../env -I../../common
objs  :=

define compile_template
$(1).riscv: $(wildcard $(src_dir)/$(1)/*) $(wildcard $(src_dir)/common/*)
	$$(RISCV_GCC) $$(incs) $$(RISCV_GCC_OPTS) -o $$@ $(wildcard $(src_dir)/$(1)/*.c) $(wildcard $(src_dir)/common/*.c) $(wildcard $(src_dir)/common/*.S) $$(RISCV_LINK_OPTS)
endef

# $(foreach bmark,$(bmarks),$(eval $(call compile_template,$(bmark))))

vector: $(rvv_target)
$(rvv_target):
	$(RISCV_GCC) $(incs) $(RISCV_GCC_VEC_OPTS) -o $@ $(SOURCE_FILES) $(RISCV_LINK_OPTS)
	$(RISCV_OBJDUMP) $@ > $@.dmp

#	$(RISCV_GCC) $(incs) $(RISCV_GCC_VEC_OPTS) -o $@ $(wildcard *.c) ../../common/syscalls_vector.c ../../common/crt.S $(RISCV_LINK_OPTS)

scalar: $(serial_target)
$(serial_target):
	$(RISCV_GCC) $(incs) $(RISCV_GCC_SCALAR_OPTS) -o $@ $(SOURCE_FILES) $(RISCV_LINK_OPTS)
	$(RISCV_OBJDUMP) $@ > $@.dmp

#	$(RISCV_GCC) $(incs) $(RISCV_GCC_SCALAR_OPTS) -o $@ $(wildcard *.c) ../../common/syscalls.c ../../common/crt.S $(RISCV_LINK_OPTS)

assembly: $(rvv_target)
	$(RISCV_GCC) $(incs) $(RISCV_GCC_VEC_OPTS) -S -o $^.asm.S $(SOURCE_FILES) $(RISCV_LINK_OPTS)

#------------------------------------------------------------
# Build and run benchmarks on riscv simulator

#------------------------------------------------------------
# Default

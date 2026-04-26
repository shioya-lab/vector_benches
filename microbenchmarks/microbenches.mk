RISCV_GCC ?= riscv$(XLEN)-unknown-elf-gcc

# Try to locate Sniper headers from common local layouts.
# Note: paths in included makefiles are evaluated relative to the including directory,
# so we anchor to this file's directory.
MICROBENCHES_MK_DIR := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))
SNIPER_CANDIDATES ?= \
	$(abspath $(MICROBENCHES_MK_DIR)/../../prave_next2/sniper) \
	$(abspath $(MICROBENCHES_MK_DIR)/../../../prave_next2/sniper) \
	$(abspath $(MICROBENCHES_MK_DIR)/../../sniper) \
	$(abspath $(MICROBENCHES_MK_DIR)/../../../sniper) \
	$(abspath $(MICROBENCHES_MK_DIR)/../../../../sniper)
SNIPER_ROOT ?= $(firstword $(foreach d,$(SNIPER_CANDIDATES),$(if $(wildcard $(d)/include/sim_api.h),$(d),)))
SNIPER_INCLUDE ?= $(SNIPER_ROOT)/include

ifeq ($(wildcard $(SNIPER_INCLUDE)/sim_api.h),)
$(error "Could not find Sniper headers. Set SNIPER_ROOT=/path/to/sniper (expected: $(SNIPER_INCLUDE)/sim_api.h)")
endif

RISCV_GCC_VEC_OPTS ?= \
	-O2 \
	-I$(SNIPER_INCLUDE) \
	-march=rv64gcv \
	-DPREALLOCATE=1 -mcmodel=medany \
	-DUSE_RISCV_VECTOR

RISCV_GCC_SCALAR_OPTS ?= \
	-march=rv64g \
	-O3 \
	-funroll-loops \
	-I$(SNIPER_INCLUDE) \
	-DPREALLOCATE=1 -mcmodel=medany

RISCV_LINK_OPTS =

LLVM ?= /riscv

SNIPER_ROOT ?= $(realpath ../../../sniper ../../../../sniper)

VLEN ?= 256
DLEN ?= $(VLEN)

ifeq ($(APP_NAME),)
	$(error "APP_NAME should be set")
endif

rvv_target    ?= bin/rvv-test
serial_target ?= bin/serial-test

rvv_sift    ?= $(basename $(notdir $(rvv_target)))_v$(VLEN).sift
serial_sift ?= $(basename $(notdir $(serial_target))).sift

# QEMU user-mode binary (e.g. qemu-riscv64). Override as needed.
QEMU ?= qemu-riscv64

# Sniper QEMU frontend plugin (built in prave_next2/sniper with BUILD_QEMU=1, BUILD_RISCV=1)
QEMU_FRONTEND ?= $(SNIPER_ROOT)/frontend/qemu-frontend/libqemu-frontend.so

# Optional: set to a RISC-V Linux sysroot prefix for qemu-user dynamic binaries
# e.g. QEMU_LD_PREFIX=/opt/riscv/sysroot
QEMU_LD_PREFIX ?=
QEMU_OPTS ?=

QEMU_USE_ROI ?= on
QEMU_FF_TARGET ?= 0
QEMU_DETAILED_TARGET ?= 0
# Extra comma-prefixed plugin options, e.g.:
#   QEMU_FRONTEND_EXTRA=,blocksize=1000000,verbose=on
QEMU_FRONTEND_EXTRA ?=

ifeq ($(strip $(QEMU_LD_PREFIX)),)
  ifneq ($(wildcard /usr/riscv64-linux-gnu),)
    QEMU_LD_PREFIX := /usr/riscv64-linux-gnu
  endif
endif

.PHONY: runqemu-v runqemu-s runqemu-debug-v runqemu-debug-s

define _qemu_env
LD_LIBRARY_PATH="$(SNIPER_ROOT)/xed_kit/lib:$(SNIPER_ROOT)/lib:$${LD_LIBRARY_PATH:-}" \
$(if $(strip $(QEMU_LD_PREFIX)),QEMU_LD_PREFIX="$(QEMU_LD_PREFIX)" ,)
endef

runqemu-v: $(rvv_target)
	$(MAKE) $(rvv_sift)

$(rvv_sift): $(rvv_target)
	@test -f "$(QEMU_FRONTEND)" || (echo "ERROR: QEMU_FRONTEND not found: $(QEMU_FRONTEND). Build prave_next2/sniper with BUILD_QEMU=1 (and RV8_HOME present)." >&2 && exit 2)
	@set +e; \
	$(_qemu_env) "$(QEMU)" \
		-plugin "$(QEMU_FRONTEND),output_file=$(basename $@),use_roi=$(QEMU_USE_ROI),fast_forward_target=$(QEMU_FF_TARGET),detailed_target=$(QEMU_DETAILED_TARGET)$(QEMU_FRONTEND_EXTRA)" \
		$(QEMU_OPTS) \
		"$^" > qemu-v.$(VLEN).log 2>&1; \
	rc="$$?"; \
	set -e; \
	if [ "$$rc" -ne 0 ] && [ -s "$@" ]; then \
		echo "WARN: qemu exited $$rc but '$@' exists" >> qemu-v.$(VLEN).log; \
		exit 0; \
	fi; \
	exit "$$rc"

runqemu-s: $(serial_target)
	$(MAKE) $(serial_sift)

$(serial_sift): $(serial_target)
	@test -f "$(QEMU_FRONTEND)" || (echo "ERROR: QEMU_FRONTEND not found: $(QEMU_FRONTEND). Build prave_next2/sniper with BUILD_QEMU=1 (and RV8_HOME present)." >&2 && exit 2)
	@set +e; \
	$(_qemu_env) "$(QEMU)" \
		-plugin "$(QEMU_FRONTEND),output_file=$(basename $@),use_roi=$(QEMU_USE_ROI),fast_forward_target=$(QEMU_FF_TARGET),detailed_target=$(QEMU_DETAILED_TARGET)$(QEMU_FRONTEND_EXTRA)" \
		$(QEMU_OPTS) \
		"$^" > qemu-s.log 2>&1; \
	rc="$$?"; \
	set -e; \
	if [ "$$rc" -ne 0 ] && [ -s "$@" ]; then \
		echo "WARN: qemu exited $$rc but '$@' exists" >> qemu-s.log; \
		exit 0; \
	fi; \
	exit "$$rc"

runqemu-debug-v: $(rvv_target)
	@test -f "$(QEMU_FRONTEND)" || (echo "ERROR: QEMU_FRONTEND not found: $(QEMU_FRONTEND). Build prave_next2/sniper with BUILD_QEMU=1 (and RV8_HOME present)." >&2 && exit 2)
	$(_qemu_env) "$(QEMU)" \
		-plugin "$(QEMU_FRONTEND),output_file=$(basename $(rvv_sift)),use_roi=$(QEMU_USE_ROI),fast_forward_target=$(QEMU_FF_TARGET),detailed_target=$(QEMU_DETAILED_TARGET),verbose=on$(QEMU_FRONTEND_EXTRA)" \
		$(QEMU_OPTS) \
		"$^" > qemu-v.$(VLEN).log 2>&1

runqemu-debug-s: $(serial_target)
	@test -f "$(QEMU_FRONTEND)" || (echo "ERROR: QEMU_FRONTEND not found: $(QEMU_FRONTEND). Build prave_next2/sniper with BUILD_QEMU=1 (and RV8_HOME present)." >&2 && exit 2)
	$(_qemu_env) "$(QEMU)" \
		-plugin "$(QEMU_FRONTEND),output_file=$(basename $(serial_sift)),use_roi=$(QEMU_USE_ROI),fast_forward_target=$(QEMU_FF_TARGET),detailed_target=$(QEMU_DETAILED_TARGET),verbose=on$(QEMU_FRONTEND_EXTRA)" \
		$(QEMU_OPTS) \
		"$^" > qemu-s.log 2>&1

clean-qemu:
	rm -rf *.sift
	rm -rf qemu-*.log


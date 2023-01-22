DIR += memcpy_scalar
DIR += memcpy_vector
DIR += pointer_chase
# DIR += printf
DIR += rvv_branch
DIR += rvv_index
DIR += rvv_matmul
DIR += rvv_memcpy
DIR += rvv_reduce
DIR += rvv_saxpy
DIR += rvv_sgemm
DIR += rvv_strcmp
DIR += rvv_strcpy
DIR += rvv_strlen
DIR += rvv_strncpy
DIR += spmv

SUBDIRSCLEAN = $(addsuffix clean,$(DIR))

VLEN = 256

.PHONY: $(DIR) $(SUBDIRSCLEAN)

all: $(DIR)
	$(MAKE) stats

$(DIR):
	$(MAKE) -C $@ VLEN=$(VLEN) runsniper-ooo-v
	$(MAKE) -C $@ VLEN=$(VLEN) runsniper-ino-v
	$(MAKE) -C $@ VLEN=$(VLEN) runsniper-vio-v
	$(MAKE) -C $@ VLEN=$(VLEN) runsniper-ooo-s
	$(MAKE) -C $@ VLEN=$(VLEN) runsniper-ino-s

stats:
	for dir in `ls -1 | grep rvv`; do \
		echo -n $$dir " "; paste $${dir}/cycle.io $${dir}/cycle.vio $${dir}/cycle.ooo; \
	done

clean: $(SUBDIRSCLEAN)

$(addsuffix clean,$(DIR)):
	echo $<
	$(MAKE) -C $(subst clean,,$@) clean

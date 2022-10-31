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

SUBDIRSCLEAN = $(addsuffix clean,$(DIR))

.PHONY: $(DIR) $(SUBDIRSCLEAN)

all: $(DIR)

$(DIR):
	$(MAKE) -C $@ run
	$(MAKE) -C $@ run-io

clean: $(SUBDIRSCLEAN)

$(addsuffix clean,$(DIR)):
	echo $<
	$(MAKE) -C $(subst clean,,$@) clean

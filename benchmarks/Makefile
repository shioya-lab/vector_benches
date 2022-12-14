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
	mt-vvadd \
	mt-matmul \


bmarks = dhrystone spmv

.PHONY: $(bmarks)

all: $(bmarks)

$(bmarks):
	$(MAKE) -C $@ runspike-v runspike-s
	$(MAKE) -C $@ runsniper

dir_clean = $(addsuffix _clean,$(bmarks))

clean:
	$(MAKE) $(dir_clean)

$(dir_clean):
	$(MAKE) -C $(subst _clean,,$@) clean

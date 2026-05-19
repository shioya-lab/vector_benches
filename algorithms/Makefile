# Graph kernels bc / cc_sv / pr_spmv / tc live under ../graph-v-rvv10-wsg/algorithms/ ;
# build (vecgraph + link) via ../graph-v-rvv10-wsg .
GRAPH_DIR := ../graph-v-rvv10-wsg
EXT_ALGS := bc cc_sv pr_spmv tc

.PHONY: all $(EXT_ALGS) clean
all: $(EXT_ALGS)

$(EXT_ALGS):
	$(MAKE) -C $(GRAPH_DIR) $@.riscv_rvv10.x ARCH=riscv ALG=$@

clean:
	$(MAKE) -C $(GRAPH_DIR) clean

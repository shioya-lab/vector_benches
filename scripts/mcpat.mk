.PHONY: mcpat_scalar_ooo mcpat_vec_ooo mcpat_scalar_to_vec mcpat_vec_to_scalar

MCPAT_MK     = $(realpath ../../../scripts/mcpat.mk ../../../../scripts/mcpat.mk)

SNIPER2MCPAT = $(realpath ../../../../sniper2mcpat/sniper2mcpat.py ../../../../../sniper2mcpat/sniper2mcpat.py)

MCPAT_TEMPLATE_XML         = $(realpath ../../mcpat_common/mcpat.template.vec.xml    ../../../mcpat_common/mcpat.template.vec.xml    ../../../../mcpat_common/mcpat.template.vec.xml)
CFG_VEC_OOO_XML     	   = $(realpath ../../mcpat_common/cfg.v$(VLEN)_d$(DLEN).ooo.xml    ../../../mcpat_common/cfg.v$(VLEN)_d$(DLEN).ooo.xml 	 ../../../../mcpat_common/cfg.v$(VLEN)_d$(DLEN).ooo.xml)
CFG_VEC_INO_XML     	   = $(realpath ../../mcpat_common/cfg.v$(VLEN)_d$(DLEN).ino.xml    ../../../mcpat_common/cfg.v$(VLEN)_d$(DLEN).ino.xml 	 ../../../../mcpat_common/cfg.v$(VLEN)_d$(DLEN).ino.xml)
CFG_SCALAR_OOO_XML  	   = $(realpath ../../mcpat_common/cfg.scalar.ooo.xml        ../../../mcpat_common/cfg.scalar.ooo.xml     	 ../../../../mcpat_common/cfg.scalar.ooo.xml)
CFG_SCALAR_INO_XML  	   = $(realpath ../../mcpat_common/cfg.scalar.ino.xml        ../../../mcpat_common/cfg.scalar.ino.xml     	 ../../../../mcpat_common/cfg.scalar.ino.xml)
CFG_SCALAR_TO_VEC_OOO_XML  = $(realpath ../../mcpat_common/cfg.scalar_to_vec.xml     ../../../mcpat_common/cfg.scalar_to_vec.xml  	 ../../../../mcpat_common/cfg.scalar_to_vec.xml)
CFG_VEC_TO_SCALAR_XML      = $(realpath ../../mcpat_common/cfg.vec_to_scalar.xml     ../../../mcpat_common/cfg.vec_to_scalar.xml     ../../../../mcpat_common/cfg.vec_to_scalar.xml)
CFG_V_TO_S_NGS_XML         = $(realpath ../../mcpat_common/cfg.v_to_s.ngs.xml        ../../../mcpat_common/cfg.v_to_s.ngs.xml        ../../../../mcpat_common/cfg.v_to_s.ngs.xml)
CFG_DCACHE_XML             = $(realpath ../../mcpat_common/cfg.dcache.xml            ../../../mcpat_common/cfg.dcache.xml            ../../../../mcpat_common/cfg.dcache.xml)
CFG_TEST_XML               = $(realpath ../../mcpat_common/cfg.test.xml     ../../../mcpat_common/cfg.test.xml     ../../../../mcpat_common/cfg.test.xml)


mcpat_test_%:
	mkdir -p $@
	$(MAKE) _$@ -C $@ -f $(MCPAT_MK)

_mcpat_test_%:
	sed "s/FP_REG_LENGTH/256/g" $(CFG_TEST_XML) | sed "s/FP_REG_WIDTH/$(subst _mcpat_test_,,$@)/g" > cfg.xml
	ln -sf ../sim.stats.sqlite3 .
	python3 $(SNIPER2MCPAT) sim.stats.sqlite3 $(MCPAT_TEMPLATE_XML) scalar_ooo


execute-mcpat-ooo-v:         mcpat_scalar_ooo mcpat_scalar_ino mcpat_vec_ooo mcpat_vec_ino mcpat_scalar_to_vec mcpat_vec_to_scalar mcpat_dcache
execute-mcpat-vio-v:         mcpat_scalar_ooo mcpat_scalar_ino mcpat_vec_ooo mcpat_vec_ino mcpat_scalar_to_vec mcpat_vec_to_scalar mcpat_dcache
execute-mcpat-vio-fence-v:   mcpat_scalar_ooo mcpat_scalar_ino mcpat_vec_ooo mcpat_vec_ino mcpat_scalar_to_vec mcpat_vec_to_scalar mcpat_dcache
execute-mcpat-vio-ngs-v:     mcpat_scalar_ooo mcpat_scalar_ino mcpat_vec_ooo mcpat_vec_ino mcpat_scalar_to_vec mcpat_v_to_s_ngs mcpat_dcache
execute-mcpat-lsu-inorder-v: mcpat_scalar_ooo mcpat_scalar_ino mcpat_vec_ooo mcpat_vec_ino mcpat_scalar_to_vec mcpat_vec_to_scalar mcpat_dcache
execute-mcpat-ino-v:         mcpat_scalar_ooo mcpat_scalar_ino mcpat_vec_ooo mcpat_vec_ino mcpat_scalar_to_vec mcpat_vec_to_scalar mcpat_dcache
execute-mcpat-ooo-s:         mcpat_scalar_ooo mcpat_dcache
execute-mcpat-ino-s:         mcpat_scalar_ooo mcpat_scalar_ino mcpat_dcache


mcpat_scalar_ooo:
	mkdir -p scalar_ooo
	$(MAKE) _mcpat_scalar_ooo -C scalar_ooo -f $(MCPAT_MK)

_mcpat_scalar_ooo:
	ln -sf $(CFG_SCALAR_OOO_XML) cfg.xml
	ln -sf ../sim.stats.sqlite3 .
	python3 $(SNIPER2MCPAT) sim.stats.sqlite3 $(MCPAT_TEMPLATE_XML) scalar_ooo

mcpat_scalar_ino:
	mkdir -p scalar_ino
	$(MAKE) _mcpat_scalar_ino -C scalar_ino -f $(MCPAT_MK)

_mcpat_scalar_ino:
	ln -sf $(CFG_SCALAR_INO_XML) cfg.xml
	ln -sf ../sim.stats.sqlite3 .
	python3 $(SNIPER2MCPAT) sim.stats.sqlite3 $(MCPAT_TEMPLATE_XML) scalar_ino

mcpat_vec_ooo:
	mkdir -p vec_ooo
	$(MAKE) _mcpat_vec_ooo -C vec_ooo -f $(MCPAT_MK)

_mcpat_vec_ooo:
	ln -sf $(CFG_VEC_OOO_XML) cfg.xml
	ln -sf ../sim.stats.sqlite3 .
	python3 $(SNIPER2MCPAT) sim.stats.sqlite3 $(MCPAT_TEMPLATE_XML) vec_ooo


mcpat_vec_ino:
	mkdir -p vec_ino
	$(MAKE) _mcpat_vec_ino -C vec_ino -f $(MCPAT_MK)

_mcpat_vec_ino:
	ln -sf $(CFG_VEC_INO_XML) cfg.xml
	ln -sf ../sim.stats.sqlite3 .
	python3 $(SNIPER2MCPAT) sim.stats.sqlite3 $(MCPAT_TEMPLATE_XML) vec_ino


mcpat_scalar_to_vec:
	mkdir -p scalar_to_vec
	$(MAKE) _mcpat_scalar_to_vec -C scalar_to_vec -f $(MCPAT_MK)

_mcpat_scalar_to_vec:
	ln -sf $(CFG_SCALAR_TO_VEC_OOO_XML) cfg.xml
	ln -sf ../sim.stats.sqlite3 .
	python3 $(SNIPER2MCPAT) sim.stats.sqlite3 $(MCPAT_TEMPLATE_XML) scalar_to_vec

mcpat_vec_to_scalar:
	mkdir -p vec_to_scalar
	$(MAKE) _mcpat_vec_to_scalar -C vec_to_scalar -f $(MCPAT_MK)

_mcpat_vec_to_scalar:
	ln -sf $(CFG_VEC_TO_SCALAR_XML) cfg.xml
	ln -sf ../sim.stats.sqlite3 .
	python3 $(SNIPER2MCPAT) sim.stats.sqlite3 $(MCPAT_TEMPLATE_XML) vec_to_scalar


mcpat_v_to_s_ngs:
	mkdir -p v_to_s_ngs
	$(MAKE) _mcpat_v_to_s_ngs -C v_to_s_ngs -f $(MCPAT_MK)

_mcpat_v_to_s_ngs:
	ln -sf $(CFG_V_TO_S_NGS_XML) cfg.xml
	ln -sf ../sim.stats.sqlite3 .
	python3 $(SNIPER2MCPAT) sim.stats.sqlite3 $(MCPAT_TEMPLATE_XML) v_to_s_ngs

mcpat_dcache:
	mkdir -p dcache
	$(MAKE) _mcpat_dcache -C dcache -f $(MCPAT_MK)

_mcpat_dcache:
	ln -sf $(CFG_DCACHE_XML) cfg.xml
	ln -sf ../sim.stats.sqlite3 .
	python3 $(SNIPER2MCPAT) sim.stats.sqlite3 $(MCPAT_TEMPLATE_XML) vec_ino

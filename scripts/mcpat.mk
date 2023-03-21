.PHONY: mcpat_scalar_ooo mcpat_vec_ooo mcpat_scalar_to_vec mcpat_vec_to_scalar

MCPAT_MK     = $(realpath ../../../scripts/mcpat.mk ../../../../scripts/mcpat.mk)

SNIPER2MCPAT = $(realpath ../../../../sniper2mcpat/sniper2mcpat.py ../../../../../sniper2mcpat/sniper2mcpat.py)

MCPAT_TEMPLATE_XML         = $(realpath ../../mcpat_common/mcpat.template.vec.xml    ../../../mcpat_common/mcpat.template.vec.xml    ../../../../mcpat_common/mcpat.template.vec.xml)
CFG_VEC_OOO_XML     	   = $(realpath ../../mcpat_common/cfg.v$(VLEN)_d$(DLEN).ooo.xml    ../../../mcpat_common/cfg.v$(VLEN)_d$(DLEN).ooo.xml 	 ../../../../mcpat_common/cfg.v$(VLEN)_d$(DLEN).ooo.xml)
CFG_VEC_INO_XML     	   = $(realpath ../../mcpat_common/cfg.v$(VLEN)_d$(DLEN).ino.xml    ../../../mcpat_common/cfg.v$(VLEN)_d$(DLEN).ino.xml 	 ../../../../mcpat_common/cfg.v$(VLEN)_d$(DLEN).ino.xml)
CFG_SCALAR_OOO_XML  	   = $(realpath ../../mcpat_common/cfg.scalar.ooo.xml        ../../../mcpat_common/cfg.scalar.ooo.xml     	 ../../../../mcpat_common/cfg.scalar.ooo.xml)
CFG_SCALAR_INO_XML  	   = $(realpath ../../mcpat_common/cfg.scalar.ino.xml        ../../../mcpat_common/cfg.scalar.ino.xml     	 ../../../../mcpat_common/cfg.scalar.ino.xml)
CFG_SCALAR_TO_VEC_OOO_XML  = $(realpath ../../mcpat_common/cfg.scalar_to_vec.xml     ../../../mcpat_common/cfg.scalar_to_vec.xml  	 ../../../../mcpat_common/cfg.scalar_to_vec.xml)
CFG_SCALAR_TO_VEC_INO_XML  = $(realpath ../../mcpat_common/cfg.scalar_to_vec.ino.xml ../../../mcpat_common/cfg.scalar_to_vec.ino.xml ../../../../mcpat_common/cfg.scalar_to_vec.ino.xml)
CFG_VEC_TO_SCALAR_XML      = $(realpath ../../mcpat_common/cfg.vec_to_scalar.xml     ../../../mcpat_common/cfg.vec_to_scalar.xml     ../../../../mcpat_common/cfg.vec_to_scalar.xml)

execute-mcpat-ooo-v: mcpat_scalar_ooo mcpat_scalar_ino mcpat_vec_ooo mcpat_vec_ino mcpat_scalar_to_vec mcpat_vec_to_scalar
	paste scalar_ooo/scalar.csv scalar_ino/scalar.csv vec_ooo/vec.csv vec_ino/vec.csv  vec_to_scalar/vec_to_scalar.csv scalar_to_vec/scalar_to_vec.csv | \
		sed 's/sim.stats.mcpat.output.txt//g' | \
		sed 's/^/$(APP_NAME)-OoO-V,$(shell cat cycle)/g' > power.csv
	paste scalar_ooo/scalar.area.csv scalar_ino/scalar.area.csv vec_ooo/vec.area.csv vec_ino/vec.area.csv  vec_to_scalar/vec_to_scalar.area.csv scalar_to_vec/scalar_to_vec.area.csv | \
		sed 's/sim.stats.mcpat.output.txt//g' | \
		sed 's/^/$(APP_NAME)-OoO-V,$(shell cat cycle)/g' > area.csv

execute-mcpat-vio-v: mcpat_scalar_ooo mcpat_scalar_ino mcpat_vec_ooo mcpat_vec_ino mcpat_scalar_to_vec mcpat_vec_to_scalar
	paste scalar_ooo/scalar.csv scalar_ino/scalar.csv vec_ooo/vec.csv vec_ino/vec.csv  vec_to_scalar/vec_to_scalar.csv scalar_to_vec/scalar_to_vec.csv | \
		sed 's/sim.stats.mcpat.output.txt//g' | \
		sed 's/^/$(APP_NAME)-VIO-V,$(shell cat cycle)/g' > power.csv
	paste scalar_ooo/scalar.area.csv scalar_ino/scalar.area.csv vec_ooo/vec.area.csv vec_ino/vec.area.csv  vec_to_scalar/vec_to_scalar.area.csv scalar_to_vec/scalar_to_vec.area.csv | \
		sed 's/sim.stats.mcpat.output.txt//g' | \
		sed 's/^/$(APP_NAME)-VIO-V,$(shell cat cycle)/g' > area.csv

execute-mcpat-ino-v: mcpat_scalar_ooo mcpat_scalar_ino mcpat_vec_ooo mcpat_vec_ino mcpat_scalar_to_vec mcpat_vec_to_scalar
	paste scalar_ooo/scalar.csv scalar_ino/scalar.csv vec_ooo/vec.csv vec_ino/vec.csv  vec_to_scalar/vec_to_scalar.csv scalar_to_vec/scalar_to_vec.csv | \
		sed 's/sim.stats.mcpat.output.txt//g' | \
		sed 's/^/$(APP_NAME)-InO-V,$(shell cat cycle)/g' > power.csv
	paste scalar_ooo/scalar.area.csv scalar_ino/scalar.area.csv vec_ooo/vec.area.csv vec_ino/vec.area.csv  vec_to_scalar/vec_to_scalar.area.csv scalar_to_vec/scalar_to_vec.area.csv | \
		sed 's/sim.stats.mcpat.output.txt//g' | \
		sed 's/^/$(APP_NAME)-InO-V,$(shell cat cycle)/g' > area.csv

execute-mcpat-ooo-s: mcpat_scalar_ooo
	paste scalar_ooo/scalar.csv | \
		sed 's/sim.stats.mcpat.output.txt//g' | \
		sed 's/^/$(APP_NAME)-OoO-S,$(shell cat cycle)/g' > power.csv
	paste scalar_ooo/scalar.area.csv | \
		sed 's/sim.stats.mcpat.output.txt//g' | \
		sed 's/^/$(APP_NAME)-OoO-S,$(shell cat cycle)/g' > area.csv

execute-mcpat-ino-s: mcpat_scalar_ooo mcpat_scalar_ino
	paste scalar_ooo/scalar.csv scalar_ino/scalar.csv | \
		sed 's/sim.stats.mcpat.output.txt//g' | \
		sed 's/^/$(APP_NAME)-InO-S,$(shell cat cycle)/g' > power.csv
	paste scalar_ino/scalar.area.csv | \
		sed 's/sim.stats.mcpat.output.txt//g' | \
		sed 's/^/$(APP_NAME)-InO-S,$(shell cat cycle)/g' > area.csv


mcpat_scalar_ooo:
	mkdir -p scalar_ooo
	$(MAKE) _mcpat_scalar_ooo -C scalar_ooo -f $(MCPAT_MK)

_mcpat_scalar_ooo:
	ln -sf $(CFG_SCALAR_OOO_XML) cfg.xml
	ln -sf ../sim.stats.sqlite3 .
	python3 $(SNIPER2MCPAT) sim.stats.sqlite3 $(MCPAT_TEMPLATE_XML) scalar_ooo
	tr -d '\r' < sim.stats.mcpat.output.filtered.csv > scalar.csv
	tr -d '\r' < sim.stats.mcpat.output.area.csv > scalar.area.csv

mcpat_scalar_ino:
	mkdir -p scalar_ino
	$(MAKE) _mcpat_scalar_ino -C scalar_ino -f $(MCPAT_MK)

_mcpat_scalar_ino:
	ln -sf $(CFG_SCALAR_INO_XML) cfg.xml
	ln -sf ../sim.stats.sqlite3 .
	python3 $(SNIPER2MCPAT) sim.stats.sqlite3 $(MCPAT_TEMPLATE_XML) scalar_ino
	tr -d '\r' < sim.stats.mcpat.output.filtered.csv > scalar.csv
	tr -d '\r' < sim.stats.mcpat.output.area.csv > scalar.area.csv

mcpat_vec_ooo:
	mkdir -p vec_ooo
	$(MAKE) _mcpat_vec_ooo -C vec_ooo -f $(MCPAT_MK)

_mcpat_vec_ooo:
	ln -sf $(CFG_VEC_OOO_XML) cfg.xml
	ln -sf ../sim.stats.sqlite3 .
	python3 $(SNIPER2MCPAT) sim.stats.sqlite3 $(MCPAT_TEMPLATE_XML) vec_ooo
	tr -d '\r' < sim.stats.mcpat.output.filtered.csv > vec.csv
	tr -d '\r' < sim.stats.mcpat.output.area.csv > vec.area.csv


mcpat_vec_ino:
	mkdir -p vec_ino
	$(MAKE) _mcpat_vec_ino -C vec_ino -f $(MCPAT_MK)

_mcpat_vec_ino:
	ln -sf $(CFG_VEC_INO_XML) cfg.xml
	ln -sf ../sim.stats.sqlite3 .
	python3 $(SNIPER2MCPAT) sim.stats.sqlite3 $(MCPAT_TEMPLATE_XML) vec_ino
	tr -d '\r' < sim.stats.mcpat.output.filtered.csv > vec.csv
	tr -d '\r' < sim.stats.mcpat.output.area.csv > vec.area.csv


mcpat_scalar_to_vec:
	mkdir -p scalar_to_vec
	$(MAKE) _mcpat_scalar_to_vec -C scalar_to_vec -f $(MCPAT_MK)

_mcpat_scalar_to_vec:
	ln -sf $(CFG_SCALAR_TO_VEC_OOO_XML) cfg.xml
	ln -sf ../sim.stats.sqlite3 .
	python3 $(SNIPER2MCPAT) sim.stats.sqlite3 $(MCPAT_TEMPLATE_XML) scalar_to_vec
	tr -d '\r' < sim.stats.mcpat.output.filtered.csv > scalar_to_vec.csv
	tr -d '\r' < sim.stats.mcpat.output.area.csv > scalar_to_vec.area.csv

mcpat_vec_to_scalar:
	mkdir -p vec_to_scalar
	$(MAKE) _mcpat_vec_to_scalar -C vec_to_scalar -f $(MCPAT_MK)

_mcpat_vec_to_scalar:
	ln -sf $(CFG_VEC_TO_SCALAR_XML) cfg.xml
	ln -sf ../sim.stats.sqlite3 .
	python3 $(SNIPER2MCPAT) sim.stats.sqlite3 $(MCPAT_TEMPLATE_XML) vec_to_scalar
	tr -d '\r' < sim.stats.mcpat.output.filtered.csv > vec_to_scalar.csv
	tr -d '\r' < sim.stats.mcpat.output.area.csv > vec_to_scalar.area.csv

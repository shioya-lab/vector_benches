RISCV_GCC = riscv$(XLEN)-unknown-elf-gcc

RISCV_GCC_VEC_OPTS ?= \
	-O2 \
	-I/home/kimura/work/sniper/sniper/sniper/include/ \
	-march=rv64gv \
	-DPREALLOCATE=1 -mcmodel=medany \
	-DUSE_RISCV_VECTOR

RISCV_GCC_SCALAR_OPTS ?= \
	-march=rv64g \
	-O3 \
	-funroll-loops \
	-I/home/kimura/work/sniper/sniper/sniper/include/ \
	-DPREALLOCATE=1 -mcmodel=medany

RISCV_LINK_OPTS =

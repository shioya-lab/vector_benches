.PHONY: native riscv

VLEN ?= 128
ELEN ?= 64

all: native riscv

native:
	g++  -g -O2 main.cpp bfs.cpp -o bfs

riscv:
	clang++ --target=riscv64-unknown-elf -march=rv64gcv -g -O3 main.cpp bfs.cpp -o bfs.riscv -I../../common
	llvm-objdump -S -d bfs.riscv > bfs.riscv.dmp
#	riscv64-unknown-elf-g++ -march=rv64gcv -g -O2 main.cpp bfs.cpp -o bfs.riscv

run:
	../../../riscv-isa-sim/spike --isa=rv64gcv \
		--varch='vlen:$(VLEN),elen:$(ELEN)' \
		--sift rvv-test_v$(VLEN).sift \
		/riscv/riscv64-unknown-elf/bin/pk bfs.riscv < graph_5000.txt

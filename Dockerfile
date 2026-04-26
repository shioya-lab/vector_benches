FROM ubuntu:20.04
# Necessary for tzdata

ENV DEBIAN_FRONTEND=noninteractive

ARG TZ_ARG=UTC
ENV TZ=${TZ_ARG}

ARG RISCV_ARG=/riscv/
ENV RISCV=${RISCV_ARG}

# ======= build args ====
ARG USER_NAME=kimura
ARG USER_ID=1000
ARG GROUP_ID=1000

# Add i386 support for support for Pin
RUN apt-get autoclean
RUN dpkg --add-architecture i386

RUN apt-get update && apt-get install -y \
    python \
    screen \
    tmux \
    binutils \
    libc6:i386 \
    libncurses5:i386 \
    libstdc++6:i386 \
 && rm -rf /var/lib/apt/lists/*
# For building Sniper
RUN apt-get update && apt-get install -y \
    automake \
    build-essential \
    curl \
    wget \
    libboost-dev \
    libsqlite3-dev \
    zlib1g-dev \
    libbz2-dev \
 && rm -rf /var/lib/apt/lists/*
# For building RISC-V Tools
RUN apt-get update && apt-get install -y \
    autoconf \
    automake \
    autotools-dev \
    bc \
    bison \
    curl \
    device-tree-compiler \
    flex \
    gawk \
    gperf \
    libexpat-dev \
    libgmp-dev \
    libmpc-dev \
    libmpfr-dev \
    libtool \
    libusb-1.0-0-dev \
    patchutils \
    pkg-config \
    texinfo \
    zlib1g-dev \
 && rm -rf /var/lib/apt/lists/*
# Helper utilities
RUN apt-get update && apt-get install -y \
    gdb \
    gfortran \
    git \
    g++-9 \
    vim \
 && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    emacs \
    zsh \
 && rm -rf /var/lib/apt/lists/*

# ---------------------------------
# RISC-V tools (spike / pk) install
# ---------------------------------
RUN echo $RISCV
ENV PATH $PATH:$RISCV/bin
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:$RISCV/lib

RUN git clone https://github.com/riscv-software-src/riscv-isa-sim.git --recurse-submodules --depth 1 && \
    cd riscv-isa-sim && \
    ./configure --enable-histogram --prefix=$RISCV --without-boost --without-boost-asio --without-boost-regex && \
    make -j$(nproc) && \
    make install

# RUN git clone https://github.com/riscv-collab/riscv-gnu-toolchain.git -b rvv-next --depth 1 && \
#     cd riscv-gnu-toolchain && \
#     mkdir build && cd build && \
#     ../configure --prefix=$RISCV && \
#     make -j$(nproc) && \
#     make install && \
#     cd ../ && rm -rf build


# ========================
# Build Official GCC-13.0
# ========================
WORKDIR /tmp/
# Binutils
RUN curl -L ftp://ftp.gnu.org/gnu/binutils/binutils-2.40.tar.gz | tar xz && \
    cd binutils-2.40 && \
    mkdir build && \
    cd build && \
    ../configure --prefix=${RISCV} \
            --target=riscv64-unknown-elf \
            --enable-languages=c,c++ \
            --disable-multilib && \
    make -j$(nproc) && \
    make install && \
    rm -rf build

# GCC-13
RUN curl -L http://ftp.tsukuba.wide.ad.jp/software/gcc/releases/gcc-13.1.0/gcc-13.1.0.tar.gz | tar xz && \
    mkdir -p gcc-13.1.0/build_rvv && \
	cd gcc-13.1.0/build_rvv && \
	../configure --prefix=${RISCV} \
	        --target=riscv64-unknown-elf \
	        --enable-languages=c,c++ \
	        --without-headers \
	        --with-newlib \
	        --disable-threads && \
    make -j$(nproc) all-gcc && \
    make install-gcc && \
    rm -rf gcc-13.1.0/build_rvv

# Newlib
RUN curl -L ftp://sourceware.org/pub/newlib/newlib-4.3.0.20230120.tar.gz | tar xz && \
    cd newlib-4.3.0.20230120 && \
    mkdir build && cd build && \
    ../configure --prefix=${RISCV} --target=riscv64-unknown-elf && \
    make -j$(nproc) && \
    make install && \
    rm -rf build

# GCC (2nd)
RUN mkdir gcc-13.1.0/build_rvv_2nd && \
    cd gcc-13.1.0/build_rvv_2nd && \
    ../configure --prefix=${RISCV} --target=riscv64-unknown-elf --enable-languages=c,c++ --with-newlib && \
    make -j$(nproc) && \
    make install && \
    rm -rf gcc-13.1.0/build_rvv_2nd


RUN git clone https://github.com/riscv-software-src/riscv-pk.git --recurse-submodules --depth 1 && \
    cd riscv-pk && \
    mkdir -p build && \
    cd build && \
    ../configure --prefix=$RISCV --host riscv64-unknown-elf && \
    make -j$(nproc) && \
    make install && \
    cd ../ && rm -rf build

RUN git clone https://github.com/riscv-software-src/riscv-tests.git --recurse-submodules --depth 1 && \
    cd riscv-tests && \
    mkdir -p build && \
    cd build && \
    ../configure --prefix=$RISCV && \
    make -j$(nproc) && \
    make install && \
    cd ../ && rm -rf build

RUN apt-get update && apt-get install -y cmake
WORKDIR /tmp/
RUN git clone https://github.com/llvm/llvm-project.git -b release/16.x --depth 1 && \
	cd llvm-project && \
	mkdir -p build && cd build && \
	cmake -G "Unix Makefiles" \
	      -DDEFAULT_SYSROOT=${RISCV}/riscv64-unknown-elf \
	      -DCMAKE_BUILD_TYPE="Release" \
          -DCMAKE_INSTALL_PREFIX=${RISCV} \
	      -DLLVM_TARGETS_TO_BUILD="host;RISCV" \
	      -DLLVM_ENABLE_PROJECTS="clang" ../llvm && \
    make -j$(nproc) && \
    make install && \
    cd ../ && rm -rf  build

RUN echo $RISCV
RUN apt-get update && apt-get install -y sqlite3
RUN apt-get update && apt-get install -y gnuplot
RUN apt-get update && apt-get install -y libdb-dev
RUN apt-get update && apt-get install -y libboost1.71-dev
RUN apt-get update && apt-get install -y build-essential cmake libboost-dev libboost-serialization-dev libboost-filesystem-dev libboost-iostreams-dev libboost-program-options-dev zlib1g-dev libquadmath0
RUN apt-get update && apt-get install -y valgrind
RUN apt-get update && apt-get install -y ocaml ocamlbuild autoconf automake indent libtool fig2dev libnum-ocaml-dev
RUN apt-get update && apt-get install -y libbz2-dev libsqlite3-dev

RUN apt-get update && apt-get install -y python3-pip ninja-build libglib2.0-dev

# Start installing QEMU
WORKDIR /tmp/
RUN wget https://download.qemu.org/qemu-9.0.0-rc3.tar.xz && \
    tar xvJf qemu-9.0.0-rc3.tar.xz && \
    cd qemu-9.0.0-rc3 && \
    mkdir -p build && cd build && \
    ../configure --target-list=riscv64-softmmu,riscv64-linux-user --prefix=${RISCV} && \
    make -j$(nproc) && \
    make install && \
    cd ../ && rm -rf build

RUN apt-get update && apt-get install -y libjemalloc-dev libjemalloc2

RUN apt-get update && apt-get install -y rsync

ENV RISCV=/riscv-linux/

RUN curl -L ftp://ftp.gnu.org/gnu/binutils/binutils-2.40.tar.gz | tar xz && \
    mkdir -p binutils-2.40/build-linux && \
    cd binutils-2.40/build-linux && \
    ../configure --prefix=${RISCV} \
    --target=riscv64-unknown-linux-gnu \
    --enable-languages=c,c++ \
    --disable-multilib && make -j$(nproc) && \
    make install && \
    cd - && \
    rm -rf binutils-2.40/build-linux


# Linux-GCC : Linux-headers
RUN curl -L https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.4.tar.gz | tar xz && \
    cd linux-6.4 && \
    make ARCH=riscv INSTALL_HDR_PATH=${RISCV}/sysroot/usr headers_install

# GCC Build (1st)
RUN curl -L http://ftp.tsukuba.wide.ad.jp/software/gcc/releases/gcc-13.1.0/gcc-13.1.0.tar.gz | tar xz && \
    mkdir -p gcc-13.1.0/build-gcc-linux-stage1 && \
    cd gcc-13.1.0/build-gcc-linux-stage1 && \
    ../configure --prefix=${RISCV} \
    --target=riscv64-unknown-linux-gnu \
    --with-sysroot=${RISCV}/sysroot \
    --with-newlib \
    --without-headers \
    --disable-shared \
    --disable-threads \
    --with-system-zlib \
    --enable-tls \
    --enable-languages=c \
    --disable-libatomic \
    --disable-libmudflap \
    --disable-libssp \
    --disable-libquadmath \
    --disable-libgomp \
    --disable-nls \
    --disable-bootstrap \
    --src=../ \
    --disable-multilib \
    CFLAGS_FOR_TARGET="-O2   -mcmodel=medlow" \
    CXXFLAGS_FOR_TARGET="-O2   -mcmodel=medlow" && \
    make -j$(nproc) && \
    make install && \
    cd - && \
    rm -rf gcc-13.1.0/build-gcc-linux-stage1

ENV PATH $PATH:$RISCV/bin
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:$RISCV/lib

# Glibc
RUN curl -L https://ftp.gnu.org/gnu/glibc/glibc-2.38.tar.gz | tar xz && \
    mkdir -p glibc-2.38/build-glibc-linux-rv64imafdc-lp64d && \
    cd glibc-2.38/build-glibc-linux-rv64imafdc-lp64d && \
    LD_LIBRARY_PATH="" \
    CC="riscv64-unknown-linux-gnu-gcc " \
    CXX="this-is-not-the-compiler-youre-looking-for" \
    CFLAGS="  -mcmodel=medlow -g -O2 " \
    CXXFLAGS="  -mcmodel=medlow -g -O2 " \
    ASFLAGS=" -mcmodel=medlow " \
    ../configure \
    --host=riscv64-unknown-linux-gnu \
    --prefix=/usr \
    --disable-werror \
    --enable-shared \
    --enable-obsolete-rpc \
    --with-headers=${RISCV}/sysroot/usr/include \
    --disable-multilib \
    --enable-kernel=3.0.0 \
    --libdir=/usr/lib libc_cv_slibdir=/lib libc_cv_rtlddir=/lib && \
     make -j$(nproc) && \
     make install install_root=${RISCV}/sysroot && \
     make install-headers install_root=${RISCV}/sysroot && \
     cd - && \
     rm -rf glibc-2.38/build-glibc-linux-rv64imafdc-lp64d

# GCC Build (2nd)
RUN mkdir -p gcc-13.1.0/build-gcc-linux-stage2 && \
    cd gcc-13.1.0/build-gcc-linux-stage2 && \
    ../configure --prefix=${RISCV} \
    --target=riscv64-unknown-linux-gnu \
    --with-sysroot=${RISCV}/sysroot \
    --with-system-zlib \
    --enable-shared \
    --enable-tls \
    --enable-languages=c,c++,fortran \
    --disable-libmudflap \
    --disable-libssp \
    --disable-libquadmath \
    --disable-libsanitizer \
    --disable-nls \
    --disable-bootstrap \
    --disable-multilib \
    CFLAGS_FOR_TARGET="-O2   -mcmodel=medlow" \
    CXXFLAGS_FOR_TARGET="-O2   -mcmodel=medlow" && \
    make -j$(nproc) && \
    make install && \
    rm -rf gcc-13.1.0/build-gcc-linux-stage2

RUN apt-get update && apt-get install -y \
    strace \
 && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    libunwind-dev elfutils libdw-dev libelf-dev pkg-config \
 && rm -rf /var/lib/apt/lists/*

RUN curl -L https://download.kde.org/Attic/heaptrack/1.5.0/heaptrack-1.5.0.tar.xz | tar xJ && \
    cd heaptrack-1.5.0 && mkdir build && cd build && cmake -DCMAKE_BUILD_TYPE=Release .. && make -j$(nproc) && make install

RUN apt-get update && apt-get install -y python3-venv

# ===== Create User (same as external User Information) =====
RUN groupadd --gid ${GROUP_ID} ${USER_NAME} \
 && useradd  --uid ${USER_ID} --gid ${GROUP_ID} -m ${USER_NAME}

# ===== Working Directory =====
WORKDIR /workspace
RUN chown -R ${USER_ID}:${GROUP_ID} /workspace

# ===== Environment  =====
ENV HOME=/home/${USER_NAME}

# ===== Change User =====
USER ${USER_NAME}

# ===== Defalut =====
CMD ["/bin/bash"]

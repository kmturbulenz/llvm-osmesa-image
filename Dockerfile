FROM oraclelinux:8
LABEL maintainer="Håkon Strandenes <h.strandenes@km-turbulenz.no>"
LABEL description="OSMesa compiled from sources"

# Note: "yum check-update" return code 100 if there are packages to be updated,
# hence the ";" instead of "&&"
RUN dnf check-update ; \
    dnf -y update && \
    dnf -y install binutils-devel \
                   bison \
                   flex \
                   git \
                   git-lfs \
                   libxml2-devel \
                   llvm-devel \
                   llvm-toolset \
                   make \
                   oracle-epel-release-el8 \
                   patch \
                   perl-Data-Dumper \
                   python3.12 \
                   python3.12-devel \
                   python3.12-pip \
                   python3.12-pip-wheel \
                   unzip \
                   which \
                   wget \
                   xz \
                   zlib-devel && \
    dnf -y install patchelf the_silver_searcher && \
    dnf clean all && \
    alternatives --set python3 /usr/bin/python3.12

RUN python3 -m pip install --no-cache-dir --upgrade pip && \
    python3 -m pip install --no-cache-dir auditwheel \
                                          Mako \
                                          MarkupSafe \
                                          meson \
                                          pyelftools \
                                          pyyaml \
                                          setuptools \
                                          wheel

ARG TARGETARCH
ENV CPU_ARCH=${TARGETARCH}
ENV CPU_ARCH=${CPU_ARCH/amd64/x86-64-v2}
ENV CPU_ARCH=${CPU_ARCH/arm64/armv8.2-a}

ENV BUILD_ARCH=${TARGETARCH}
ENV BUILD_ARCH=${BUILD_ARCH/amd64/x86_64}
ENV BUILD_ARCH=${BUILD_ARCH/arm64/aarch64}

# Fetch and install updated CMake in /usr/local
ENV CMAKE_VER="3.31.9"
ENV CMAKE_URL="https://github.com/Kitware/CMake/releases/download/v${CMAKE_VER}/cmake-${CMAKE_VER}-linux-${BUILD_ARCH}.tar.gz"
RUN mkdir /tmp/cmake-install && \
    cd /tmp/cmake-install && \
    wget --no-verbose $CMAKE_URL && \
    tar -xf cmake-${CMAKE_VER}-linux-${BUILD_ARCH}.tar.gz -C /usr/local --strip-components=1 && \
    cd / && \
    rm -rf /tmp/cmake-install

# Fetch and install updated Ninja-build in /usr/local
RUN case "${BUILD_ARCH}" in \
        x86_64) NINJA_ARCH="" ;; \
        aarch64) NINJA_ARCH="-aarch64" ;; \
        *) echo "Unsupported architecture: ${BUILD_ARCH}" >&2; exit 1 ;; \
    esac && \
    export NINJA_URL="https://github.com/ninja-build/ninja/releases/download/v1.13.2/ninja-linux$NINJA_ARCH.zip" && \
    mkdir /tmp/ninja-install && \
    cd /tmp/ninja-install && \
    wget --no-verbose $NINJA_URL && \
    unzip ninja-linux${NINJA_ARCH}.zip -d /usr/local/bin && \
    cd / && \
    rm -rf /tmp/ninja-install

# CPU architecture for optimizations
ENV CFLAGS="-march=${CPU_ARCH}"
ENV CXXFLAGS="-march=${CPU_ARCH}"

# Download Mesa3D library
ENV MESA_VER="25.0.7"
ARG MESA_URL="https://archive.mesa3d.org/mesa-${MESA_VER}.tar.xz"
RUN mkdir -p /opt/mesa && \
    cd /opt/mesa && \
    wget --no-verbose $MESA_URL && \
    tar -xf mesa-${MESA_VER}.tar.xz && \
    rm mesa-${MESA_VER}.tar.xz

# Compile OSMesa
RUN set -o pipefail && \
    cd /opt/mesa/mesa-${MESA_VER} && \
    CC=clang CXX=clang++ meson build \
        -Dbuildtype=release \
        -Dosmesa=true \
        -Dgallium-drivers=llvmpipe \
        -Dglx=disabled \
        -Degl=disabled \
        -Dvulkan-drivers=[] \
        -Dplatforms= \
        -Dshared-llvm=disabled \
        -Dshared-glapi=disabled \
        -Dlibunwind=disabled \
        -Dprefix=/usr/local 2>&1 | tee configure.log && \
    ninja -C build install 2>&1 | tee ninja.log

ENV OSMESA_ROOT="/usr/local"

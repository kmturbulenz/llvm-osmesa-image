FROM oraclelinux:8
LABEL maintainer="Håkon Strandenes <h.strandenes@km-turbulenz.no>"
LABEL description="Mesa EGL surfaceless compiled from sources"

# Note: "yum check-update" return code 100 if there are packages to be updated,
# hence the ";" instead of "&&"
RUN dnf check-update ; \
    dnf -y update && \
    dnf -y install binutils-devel \
                   bison \
                   flex \
                   git \
                   git-lfs \
                   libdrm-devel \
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
ENV MESA_VER="26.2.2"
ENV MESA_SHA256="eeb29ca7e56cfaa8e8a79538dcf834e3b18e501c31bef5145e959ea437cc4216"
ARG MESA_URL="https://archive.mesa3d.org/mesa-${MESA_VER}.tar.xz"
RUN mkdir -p /opt/mesa && \
    cd /opt/mesa && \
    wget --no-verbose $MESA_URL && \
    echo "${MESA_SHA256}  mesa-${MESA_VER}.tar.xz" | sha256sum -c - && \
    tar -xf mesa-${MESA_VER}.tar.xz && \
    rm mesa-${MESA_VER}.tar.xz

# Compile a self-contained EGL surfaceless software-rendering stack.
RUN set -o pipefail && \
    cd /opt/mesa/mesa-${MESA_VER} && \
    CC=clang CXX=clang++ meson setup build \
        -Dbuildtype=release \
        -Degl=enabled \
        -Degl-native-platform=surfaceless \
        -Dgallium-drivers=llvmpipe \
        -Dgbm=disabled \
        -Dglvnd=disabled \
        -Dglx=disabled \
        -Dvulkan-drivers=[] \
        -Dplatforms= \
        -Dshared-llvm=disabled \
        -Dshared-glapi=disabled \
        -Dlibunwind=disabled \
        -Dprefix=/opt/mesa-egl \
        -Dlibdir=lib 2>&1 | tee configure.log && \
    ninja -C build install 2>&1 | tee ninja.log && \
    cp -a /usr/lib64/libdrm.so.2* /opt/mesa-egl/lib/

ENV MESA_EGL_ROOT="/opt/mesa-egl"

###################################
LLVM and Mesa EGL surfaceless image
###################################

This image contains LLVM from Oracle Linux packages and Mesa 26.2.2 compiled
from sources. Mesa provides EGL surfaceless rendering backed by the ``llvmpipe``
software driver, replacing the removed ``OSMesa`` interface. The image is based
on Oracle Linux 8, which means that the resulting libraries are portable to
systems with ``glibc`` 2.28 or newer.

Release artifacts contain the complete ``mesa-egl`` prefix, including public
EGL, OpenGL, and KHR headers, libraries, the ``llvmpipe`` software renderer, and
pkg-config metadata. It also includes ``libdrm.so.2``, so no host libdrm
installation, GPU, X11, or Wayland is needed.

Usage of these libraries (e.g. by VTK) requires setting the ``LD_LIBRARY_PATH``
environment variable::

    export LD_LIBRARY_PATH="${MESA_EGL_ROOT}/lib:$LD_LIBRARY_PATH"

If you want to build the image yourself locally, the command is::

    docker build -t llvm-mesa-egl-image:latest .

#####################
LLVM and OSMesa image
#####################

This image contains recent versions of LLVM and OSMesa compiled from sources.
The image is based on Centos 7, which means that the resulting libraries
are fairly portable in terms of ``glibc`` versions (minimum ``glibc`` 2.17 -
same as ``manylinux2014`` minimum requirement).

This image can then be used to compile the VTK library against OSMesa.

Images are automatically build with Github Actions and are published at the
`Github container registry <https://github.com/kmturbulenz/llvm-osmesa-image/pkgs/container/llvm-osmesa-image>`_.
If you want to build the image yourself locally, the command is::

    docker build -t llvm-osmesa-image:latest .

#####################
LLVM and OSMesa image
#####################

This image contains recent versions of LLVM and OSMesa compiled from sources.
The image is based on Oracle Linux 8, which means that the resulting libraries
are fairly portable in terms of ``glibc`` versions (minimum ``glibc`` 2.28).

If you want to build the image yourself locally, the command is::

    docker build -t llvm-osmesa-image:latest .

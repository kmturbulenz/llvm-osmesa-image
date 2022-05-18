#####################
LLVM and OSMesa image
#####################

This image contains recent versions of LLVM and OSMesa compiled from sources.
The image is based on Centos 7, which means that the resulting libraries
are fairly portable in terms of ``glibc`` versions (minimum ``glibc`` 2.17 -
same as ``manylinux2014`` minimum requirement).

This image can then be used to compile the VTK library against OSMesa.
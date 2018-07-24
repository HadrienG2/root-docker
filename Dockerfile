# Configure the container's basic properties
FROM hgrasland/spack-tests
LABEL Description="openSUSE Tumbleweed with ROOT installed" Version="6.14"
CMD bash

# Switch to a development branch of Spack with an updated ROOT package
#
# FIXME: Switch to JavierCVilla's branch once it is fixed, and upstream once it
#        is integrated.
#
RUN cd /opt/spack                                                              \
    && git remote add HadrienG2 https://github.com/HadrienG2/spack.git         \
    && git fetch HadrienG2                                                     \
    && git checkout HadrienG2/new-root-recipe-fixes

# Install a reasonably minimal version of ROOT
RUN spack install root@6.14.00 cxxstd=17 -davix -examples -gdml -memstat       \
                               -opengl +root7 +sqlite +ssl -tiff -tmva -unuran \
                               -vdt -x -xml

# Prepare the environment for running ROOT
RUN echo "spack load root" >> "$SETUP_ENV"

# Check that the ROOT install works
RUN root.exe -b -q -e "(6*7)-(6*7)"
# Configure the container's basic properties
FROM hgrasland/spack-tests
LABEL Description="openSUSE Tumbleweed with ROOT installed" Version="6.14"
CMD bash
ARG ROOT_CXX_STANDARD=17

# Switch to a development branch of Spack with an updated ROOT package
#
# FIXME: Switch to JavierCVilla's branch once it is fixed, and to upstream once
#        JavierCVilla's work is integrated.
#
RUN cd /opt/spack                                                              \
    && git remote add HadrienG2 https://github.com/HadrienG2/spack.git         \
    && git fetch HadrienG2                                                     \
    && git checkout HadrienG2/new-root-recipe-fixes

# This is a minimal ROOT build Spack specification. We record it to an
# environment variable so that clients can later use the same ROOT build.
ENV ROOT_SPACK_SPEC="root@6.14.00 cxxstd=${ROOT_CXX_STANDARD} -davix -examples \
                                  -gdml -memstat -opengl +root7 +sqlite +ssl   \
                                  -tiff -tmva -unuran -vdt -x -xml"

# Install ROOT
RUN spack install ${ROOT_SPACK_SPEC}

# Prepare the environment for running ROOT
RUN echo "spack load root" >> "$SETUP_ENV"

# Check that the ROOT install works
RUN root.exe -b -q -e "(6*7)-(6*7)"
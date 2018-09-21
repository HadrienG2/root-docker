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
    && git checkout HadrienG2/new-root-recipe-updated

# This is a reasonably minimal ROOT Spack specification. We record it to an
# environment variable so that clients can later use the same ROOT build.
#
# FIXME: In general, we would like to enable the GDML module. But it does not
#        build in C++17 mode as of ROOT 6.14. Better luck next time!
# FIXME: Once this is fixed, go back to Docker ENV statements as they are easier
#        to reason about than the SETUP_ENV hack.
#
RUN GDML_VARIANT=`[ ${ROOT_CXX_STANDARD} == 17 ]                               \
                            && echo '-gdml' || echo '+gdml'`                   \
    && echo "export ROOT_SPACK_SPEC=\"root@6.14.04 cxxstd=${ROOT_CXX_STANDARD} \
             -davix -examples ${GDML_VARIANT} -memstat +opengl +root7 +rpath   \
             +sqlite +ssl -tiff -tmva -unuran -vdt +x -xml\"" >> "$SETUP_ENV"

# Install ROOT
RUN echo "Installing ${ROOT_SPACK_SPEC}..." && spack install ${ROOT_SPACK_SPEC}

# Prepare the environment for running ROOT
RUN echo "spack load ${ROOT_SPACK_SPEC}" >> "$SETUP_ENV"

# Check that the ROOT install works
RUN root.exe -b -q -e "(6*7)-(6*7)"

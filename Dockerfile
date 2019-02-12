# Configure the container's basic properties
FROM hgrasland/spack-tests
LABEL Description="openSUSE Tumbleweed with ROOT installed"
CMD bash
ARG ROOT_VERSION=6.14.04
ARG ROOT_CXX_STANDARD=17

# This is a reasonably minimal ROOT Spack specification. We record it to an
# environment variable so that clients can later use the same ROOT build.
#
# FIXME: In general, we would like to enable the GDML module. But it does not
#        build in C++17 mode as of ROOT 6.14.04 Better luck next time!
# FIXME: Once this is fixed, go back to Docker ENV statements as they are easier
#        to reason about than the SETUP_ENV hack.
#
RUN GDML_VARIANT=`[ ${ROOT_CXX_STANDARD} == 17 ]                               \
                            && echo '-gdml' || echo '+gdml'`                   \
    && echo "export ROOT_SPACK_SPEC=\"                                         \
                root@${ROOT_VERSION} cxxstd=${ROOT_CXX_STANDARD} -davix        \
                -examples ${GDML_VARIANT} -memstat +opengl +root7 +rpath       \
                +sqlite +ssl -tiff -tmva -unuran -vdt +x -xml                  \
            \"" >> "$SETUP_ENV"

# Install ROOT
RUN echo "Installing ${ROOT_SPACK_SPEC}..." && spack install ${ROOT_SPACK_SPEC}

# Prepare the environment for running ROOT
RUN echo "spack load ${ROOT_SPACK_SPEC}" >> "$SETUP_ENV"

# Check that the ROOT install works
RUN root.exe -b -q -e "(6*7)-(6*7)"

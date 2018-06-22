# === DOCKER-SPECIFIC HACKERY ===

# Configure the container's basic properties
FROM opensuse:tumbleweed
LABEL Description="openSUSE Tumbleweed with ROOT installed" Version="6.14"
CMD bash
SHELL ["/bin/bash", "-c"]

# Build an environment setup script that works during docker build
#
# NOTE: This trickery is necessary because docker build commands are run in a
#       shell which is neither a login shell nor an interactive shell, and
#       cannot be easily turned into either. Which means that there is no clean
#       entry point for running environment setup scripts in docker build.
#
RUN touch /root/setup_env.sh                                                   \
    && echo "unset BASH_ENV" > /root/bash_env.sh                               \
    && echo "source /root/setup_env.sh" >> /root/bash_env.sh                   \
    && echo "source /root/setup_env.sh" >> /root/.bashrc
ENV BASH_ENV="/root/bash_env.sh"                                               \
    SETUP_ENV="/root/setup_env.sh"

# By default, Docker runs commands in the root directory (/). It is cleaner and
# more idiomatic to run them in our home directory (which is /root) instead.
WORKDIR /root


# === SYSTEM SETUP ===

# Update the host system
RUN zypper ref && zypper dup -y

# Install ROOT's build prerequisites (yes, they are ridiculous)
RUN zypper in -y git cmake gcc-c++ gcc binutils xorg-x11-libX11-devel          \
                 xorg-x11-libXpm-devel xorg-x11-devel xorg-x11-proto-devel     \
                 xorg-x11-libXext-devel gcc-fortran libopenssl-devel           \
                 pcre-devel Mesa glew-devel libmysqlclient-devel fftw3-devel   \
                 libcfitsio-devel graphviz-devel libdns_sd                     \
                 avahi-compat-mDNSResponder-devel openldap2-devel              \
                 python2-devel libxml2-devel krb5-devel gsl-devel libqt4-devel \
                 tbb-devel ftgl-devel gl2ps-devel lz4 liblz4-devel ninja tar   \
                 glu-devel python2-numpy python2-numpy-devel


# === INSTALL ROOT ===

# Clone the desired ROOT version
RUN git clone --branch=v6-14-00 --depth 1                                      \
    https://github.com/root-project/root.git ROOT

# Configure a reasonably minimal build of ROOT
RUN cd ROOT && mkdir build-dir && cd build-dir                                 \
    && cmake -GNinja -Dbuiltin_ftgl=OFF -Dbuiltin_glew=OFF -Dbuiltin_lz4=OFF   \
             -Dbuiltin_xxhash=ON -Dcastor=OFF -Dcxx14=ON -Ddavix=OFF           \
             -Dfail-on-missing=ON -Dgfal=OFF -Dgnuinstall=ON -Dhttp=OFF        \
             -Dmysql=OFF -Doracle=OFF -Dpgsql=OFF -Dpythia6=OFF -Dpythia8=OFF  \
             -Droot7=ON -Dssl=ON -Dvdt=OFF -Dxrootd=OFF                        \
             -DPython_ADDITIONAL_VERSIONS=2.7 ..

# Build and install ROOT
RUN cd ROOT/build-dir && ninja && ninja install

# Prepare the environment for running ROOT
RUN echo "source /usr/local/bin/thisroot.sh" >> "$SETUP_ENV"

# Check that the ROOT install works
RUN root -b -q -e "(6*7)-(6*7)"

# Get rid of the ROOT build directory to save up space
RUN rm -rf ROOT


# === FINAL CLEAN UP ===

# Discard the system package cache to save up space
RUN zypper clean
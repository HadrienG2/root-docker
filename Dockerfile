FROM opensuse:tumbleweed
LABEL Description="openSUSE Tumbleweed with ROOT installed" Version="0.1"
CMD bash


# === SYSTEM SETUP ===

# Update the host system
RUN zypper ref && zypper dup -y

# Install ROOT's build prerequisites (yes, they are ridiculous)
RUN zypper in -y git cmake gcc-c++ gcc binutils xorg-x11-libX11-devel          \
                 xorg-x11-libXpm-devel xorg-x11-devel xorg-x11-proto-devel     \
                 xorg-x11-libXext-devel gcc-fortran libopenssl-devel           \
                 pcre-devel Mesa glew-devel pkg-config libmysqlclient-devel    \
                 fftw3-devel libcfitsio-devel graphviz-devel                   \
                 libdns_sd avahi-compat-mDNSResponder-devel openldap2-devel    \
                 python-devel libxml2-devel krb5-devel gsl-devel libqt4-devel  \
                 tbb-devel ftgl-devel gl2ps-devel lz4 liblz4-devel ninja tar   \
                 glu-devel


# === INSTALL ROOT ===

# Clone the desired ROOT version
RUN git clone --branch=v6-12-06 --single-branch                                \
    https://github.com/root-project/root.git ROOT

# Configure a reasonably minimal build of ROOT
RUN cd ROOT && mkdir build-dir && cd build-dir                                 \
    && cmake -GNinja -Dbuiltin_ftgl=OFF -Dbuiltin_glew=OFF -Dbuiltin_lz4=OFF   \
             -Dcastor=OFF -Dcxx14=ON -Ddavix=OFF -Dfail-on-missing=ON          \
             -Dgfal=OFF -Dgnuinstall=ON -Dhttp=OFF -Dmysql=OFF -Doracle=OFF    \
             -Dpgsql=OFF -Dpythia6=OFF -Dpythia8=OFF -Droot7=ON -Dssl=OFF      \
             -Dxrootd=OFF ..

# Build and install ROOT
RUN cd ROOT/build-dir && ninja && ninja install

# Set up the environment for running ROOT
ENV LD_LIBRARY_PATH /usr/local/lib/root/:${LD_LIBRARY_PATH}

# Check that the ROOT install works
RUN root -b -q -e "(6*7)-(6*7)"

# Clean up to save image space
RUN rm -rf ROOT                                                                \
    && zypper clean
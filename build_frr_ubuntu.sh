#!/usr/bin/env bash
# Free Range Routing build script for Ubuntu 16.04

SRC_DIR=~/src
FRR_BRANCH='stable/7.2'
MYVERSION="-MYversion1"
nprocs=`/usr/bin/nproc`
sudo apt-get update
sudo apt-get install \
   git autoconf automake libtool make libreadline-dev texinfo \
   pkg-config libpam0g-dev libjson-c-dev bison flex python3-pytest \
   libc-ares-dev python3-dev libsystemd-dev python-ipaddress python3-sphinx \
   install-info build-essential libsystemd-dev libsnmp-dev perl libcap-dev \
   cmake libpcre3-dev

mkdir -p ~/$SRC_DIR
cd ~/$SRC_DIR
git clone -b $FRR_BRANCH https://github.com/FRRouting/frr.git

#build and install libyang
cd ~/$SRC_DIR/frr
git clone https://github.com/CESNET/libyang.git
cd libyang
mkdir build; cd build
cmake -DENABLE_LYD_PRIV=ON -DCMAKE_INSTALL_PREFIX:PATH=/usr \
      -D CMAKE_BUILD_TYPE:String="Release" ..
make -j$nprocs
sudo make install

#add frr user groups to local host
sudo groupadd -r -g 92 frr
sudo groupadd -r -g 85 frrvty
sudo adduser \
            --system \
            --ingroup frr \
            --home /var/run/frr/ \
            --gecos "FRR suite" --shell /sbin/nologin frr
sudo usermod -a -G frrvty frr

#build and install FRR
cd ~/$SRC_DIR/frr
./bootstrap.sh
./configure \
    --prefix=/usr \
    --includedir=\${prefix}/include \
    --enable-exampledir=\${prefix}/share/doc/frr/examples \
    --bindir=\${prefix}/bin \
    --sbindir=\${prefix}/lib/frr \
    --libdir=\${prefix}/lib/frr \
    --libexecdir=\${prefix}/lib/frr \
    --localstatedir=/var/run/frr \
    --sysconfdir=/etc/frr \
    --with-moduledir=\${prefix}/lib/frr/modules \
    --with-libyang-pluginsdir=\${prefix}/lib/frr/libyang_plugins \
    --enable-configfile-mask=0640 \
    --enable-logfile-mask=0640 \
    --enable-snmp=agentx \
    --enable-multipath=64 \
    --enable-user=frr \
    --enable-group=frr \
    --enable-vty-group=frrvty \
    --with-pkg-git-version \
    --with-pkg-extra-version=$MYVERSION
make -j$nprocs

sudo make install
sudo install -m 775 -o frr -g frr -d /var/log/frr
sudo install -m 775 -o frr -g frrvty -d /etc/frr
sudo install -m 640 -o frr -g frrvty tools/etc/frr/vtysh.conf /etc/frr/vtysh.conf
sudo install -m 640 -o frr -g frr tools/etc/frr/frr.conf /etc/frr/frr.conf
sudo install -m 640 -o frr -g frr tools/etc/frr/daemons.conf /etc/frr/daemons.conf
sudo install -m 640 -o frr -g frr tools/etc/frr/daemons /etc/frr/daemons

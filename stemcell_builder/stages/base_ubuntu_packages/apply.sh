#!/usr/bin/env bash

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash

debs="libssl-dev lsof strace bind9-host dnsutils tcpdump iputils-arping \
curl wget libcurl3 libcurl3-dev bison libreadline6-dev \
libxml2 libxml2-dev libxslt1.1 libxslt1-dev zip unzip \
nfs-common flex psmisc apparmor-utils iptables sysstat \
rsync openssh-server traceroute libncurses5-dev quota \
libaio1 gdb libcap2-bin libcap2-dev libbz2-dev \
cmake uuid-dev libgcrypt-dev ca-certificates \
scsitools mg htop module-assistant debhelper runit parted \
cloud-guest-utils anacron software-properties-common \
xfsprogs"

if is_ppc64le; then
  debs="$debs \
libreadline-dev libtool texinfo ppc64-diag libffi-dev \
libruby bundler libgmp-dev libgmp3-dev libmpfr-dev libmpc-dev"
fi

pkg_mgr install $debs

if ! is_ppc64le; then
  # we need newer rsyslog; this comes from the upstream project's own repo
  run_in_chroot $chroot "add-apt-repository ppa:adiscon/v8-stable"
  # needed to remove rsyslog-mmjsonparse on ppc64le
  # because of this issue https://gist.github.com/allomov-altoros/cd579aa76f3049bee9c7
  pkg_mgr install "rsyslog rsyslog-relp rsyslog-gnutls"
  pkg_mgr install "rsyslog-mmjsonparse"
else
  pkg_mgr install "libsystemd-journal-dev libestr-dev libjson0 libjson0-dev uuid-dev python-docutils libcurl4-openssl-dev"

  run_in_chroot $chroot "
    function check_md5 {
      md5sum --check --status $1.md5
    }

    cd /tmp
    
    cat > ./liblogging-1.0.5.tar.gz.md5 <<EOF
    44b8ce2daa1bfb84c9feaf42f9925fd7  liblogging-1.0.5.tar.gz
    EOF
    
    cat > ./librelp-1.2.9.tar.gz.md5 <<EOF
    6df8123486b6aafde90c64a0a5951892  librelp-1.2.9.tar.gz
    EOF 

    cat > ./rsyslog-8.15.0.tar.gz.md5 <<EOF
    3fab1c48e8d8111d4cc412482e2fe39d  rsyslog-8.15.0.tar.gz
    EOF 

    # on ppc64le compile from source as the .deb packages are not available
    # from the repo above
    wget http://download.rsyslog.com/liblogging/liblogging-1.0.5.tar.gz
    check_md5 liblogging-1.0.5.tar.gz
    [ $? != 0 ] && {echo \"Checksum error with liblogging-1.0.5.tar.gz\" && exit 1}
    
    wget http://download.rsyslog.com/librelp/librelp-1.2.9.tar.gz
    check_md5 librelp-1.2.9.tar.gz
    [ $? != 0 ] && {echo \"Checksum error with librelp-1.2.9.tar.gz\" && exit 1}
    
    wget http://www.rsyslog.com/download/files/download/rsyslog/rsyslog-8.15.0.tar.gz
    check_md5 rsyslog-8.15.0.tar.gz
    [ $? != 0 ] && {echo \"Checksum error with rsyslog-8.15.0.tar.gz\" && exit 1}

    tar xvfz liblogging-1.0.5.tar.gz
    cd liblogging-1.0.5
    ./configure --disable-man-pages --prefix=/usr
    make && sudo make install
    cd ..

    tar xvfz librelp-1.2.9.tar.gz
    cd librelp-1.2.9
    ./configure --prefix=/usr
    make && sudo make install
    cd ..

    tar xvfz rsyslog-8.15.0.tar.gz
    cd rsyslog-8.15.0
    ./configure --enable-mmjsonparse --enable-gnutls --enable-relp --prefix=/usr
    make && make install
  "
fi


exclusions="postfix"
pkg_mgr purge --auto-remove $exclusions

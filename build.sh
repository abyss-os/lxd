#!/bin/sh
# WARNING: you MUST run this from inside an abyss container
# no really it WILL BREAK otherwise

# clean up
rm -rf esh \
    metadata.yaml \
    rootfs

ABYSS_CORE=https://mirror.getabyss.com/abyss/core
ABYSS_DEV=https://mirror.getabyss.com/abyss/devel

# get prereqs
apk add bsdtar

# get esh, for metadata generation
wget https://raw.githubusercontent.com/jirutka/esh/v0.3.0/esh \
    && echo 'fe030e23fc1383780d08128eecf322257cec743b  esh' | sha1sum -c \
    || exit 1
chmod +x esh

# generate metadata
./esh -o metadata.yaml metadata.yaml.esh

# create base rootfs
apka() {
    apk add -X "$ABYSS_CORE" --no-cache --allow-untrusted --initdb --root rootfs "$@"
}
apka filesystem
apka abyss-keyring apk-tools busybox ca-certificates
echo "$ABYSS_CORE" > rootfs/etc/apk/repositories
echo "$ABYSS_DEV" >> rootfs/etc/apk/repositories

# prep for chroot
cp /etc/resolv.conf rootfs/etc/

# chroot inside rootfs
crun() {
    chroot rootfs "$@"
}
crun /usr/bin/busybox --install -s /usr/bin
crun apk fix --no-cache
# basic setup
crun apk add --no-cache dhcpcd openrc util-linux
crun ln -s openrc-init /sbin/init
# enable services
crun ln -s /etc/init.d/agetty /etc/init.d/agetty.console
crun rc-update add agetty.console default
crun rc-update add dhcpcd         default
# NO, NOT ALLOWED
crun sed -i 's/^persistent/#persistent/' /etc/dhcpcd.conf

# create unified tarball
bsdtar -caf abyss.tar.gz rootfs metadata.yaml

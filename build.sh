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
apka abyss-base
echo "$ABYSS_CORE" > rootfs/etc/apk/repositories
echo "$ABYSS_DEV" >> rootfs/etc/apk/repositories

# prep for chroot
cp /etc/resolv.conf rootfs/etc/

# chroot inside rootfs
crun() {
    chroot rootfs "$@"
}
# enable services
crun ln -s /etc/init.d/getty /etc/init.d/getty.console
crun rc-update add bootmisc boot
crun rc-update add getty.console default
crun rc-update add dhcpcd default
crun rc-update add loopback sysinit

# NO, NOT ALLOWED
crun sed -i 's/^persistent/#persistent/' /etc/dhcpcd.conf

# create unified tarball
bsdtar -caf abyss.tar.gz rootfs metadata.yaml

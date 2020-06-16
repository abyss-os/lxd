#!/bin/sh
# WARNING: you MUST run this from inside an abyss container
# no really it WILL BREAK otherwise

# clean up
rm -rf esh \
    metadata.yaml \
    rootfs

ARCH=$(apk --print-arch)
ABYSS_CORE=https://mirror.abyss.run/abyss/core
ABYSS_DEV=https://mirror.abyss.run/abyss/devel

case "$ARCH" in
	mips64*|riscv64) cc=none binutils=gnu;;
	*)	cc=none binutils=llvm;;
esac

# chroot inside rootfs
crun() {
    chroot rootfs "$@"
}
# create base rootfs
apka() {
    apk add -X "$ABYSS_CORE" --no-cache --allow-untrusted --initdb --root rootfs "$@"
}

# get prereqs
apk add bsdtar squashfs-tools

# get esh, for metadata generation
wget https://raw.githubusercontent.com/jirutka/esh/v0.3.0/esh \
    && echo 'fe030e23fc1383780d08128eecf322257cec743b  esh' | sha1sum -c \
    || exit 1
chmod +x esh

# generate metadata
./esh -o metadata.yaml metadata.yaml.esh

apka abyss-base
echo "$ABYSS_CORE" > rootfs/etc/apk/repositories
echo "$ABYSS_DEV" >> rootfs/etc/apk/repositories

# prep for chroot
cp /etc/resolv.conf rootfs/etc/

# enable services
crun ln -s /etc/init.d/getty /etc/init.d/getty.console
crun rc-update add getty.console default
crun rc-update add dhcpcd default
crun rc-update add loopback sysinit

# NO, NOT ALLOWED
crun sed -i 's/^persistent/#persistent/' /etc/dhcpcd.conf

# create unified tarball
echo "latest.tar.gz"
bsdtar -caf latest.tar.gz rootfs metadata.yaml

stat latest.tar.gz
# create separate images + squashfs
#bsdtar -caf latest.tar.gz metadata.yaml
#mksquashfs rootfs rootfs.squashfs -all-root

rm -vf latest.tar.gz metadata.yaml rootfs.squashfs

# now make dev
crun apk add abyss-base-dev
crun ln -s /usr/bin/gmake /usr/bin/make
crun toolchain $cc $binutils
crun adduser root abuild

./esh -o metadata.yaml metadata.dev.yaml.esh

# create unified tarball
echo "dev.tar.gz"
bsdtar -caf dev.tar.gz rootfs metadata.yaml
stat latest.tar.gz

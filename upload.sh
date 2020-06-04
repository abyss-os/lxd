#!/bin/sh
case $DRONE_STAGE_ARCH in
	amd64) buildarch=x86_64;;
	arm64) buildarch=aarch64;;
	ppc64le) buildarch=ppc64le;;
	mips64) buildarch=mips64;;
	*) echo "unknown arch" ; exit 1;;
esac

mcli cp --attr arch="${buildarch}"\;stamp="$(date +%Y%m%d)" abyss.tar.gz "master/abyss-ci/lxd/snap-${buildarch}-$(date +%Y%m%d).tgz"

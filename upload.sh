#!/bin/sh
buildarch=$(apk --print-arch)

mcli cp --attr arch="${buildarch}"\;stamp="$(date +%Y%m%d)"\;tag=latest latest.tar.gz "master/abyss-ci/lxd/latest-${buildarch}-$(date +%Y%m%d).tgz"
mcli cp --attr arch="${buildarch}"\;stamp="$(date +%Y%m%d)"\;tag=dev dev.tar.gz "master/abyss-ci/lxd/dev-${buildarch}-$(date +%Y%m%d).tgz"

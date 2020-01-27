#!/bin/sh
case $DRONE_STAGE_ARCH in
        amd64) buildarch=x86_64;;
        arm64) buildarch=aarch64;;
        *) echo "unknown arch" ; exit 1;;
esac

if [ -z "$s3_id" ] || [ -z "$s3_key" ] || [ -z "$s3_endpoint" ]; then
    echo 's3_id, s3_key and s3_endpoint environment variables are mandatory'
    return 1
fi

MCLI=mcli
[ $# -ge 1 ] && MCLI="$1"

if [ "${buildarch}" = "x86_64" ]; then
    export MC_HOST_target="https://$s3_id:$s3_key@$s3_endpoint"
    $MCLI cp abyss.tar.gz "target/$s3_id/lxd/"
fi

$MCLI cp abyss.tar.gz "master/abyss-ci/lxd-snap-${buildarch}-$(date +%Y%m%d).tgz"

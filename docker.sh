#! /bin/bash

set -e
set -x

OPTS=""

addopt () {
#	[ -n "$OPTS" ] &&
 OPTS="${OPTS} "
	OPTS="${OPTS}$*"
}

if [ -n "$MODULES" ]; then
	#OPTS="${OPTS} --build-arg MODULES=\"$MODULES\""
	addopt --build-arg MODULES=\"$MODULES\"
fi

export TMPDIR=~/contbuild/bulk/tmp

IMG=$1

set -o pipefail

buildah bud \
	-v /vol/pip-cache/birdnet:/home/pi/.cache/pip \
	-v $PWD/build-cache/apt:/var/cache/apt/archives \
	-v $PWD/build-cache/apt-lists:/var/lib/apt/lists \
	-v $PWD/build-cache/git:/home/pi/gitcache \
	-v $PWD/build-cache/caddy:/home/pi/.cache/caddy \
	--build-arg apt_proxy="http://fs2.lan:3142/" \
	 --no-cache --force-rm=false \
	-f docker/Dockerfile.$IMG \
	--tag bnpi-$IMG:latest \
	$OPTS | tee logs/$IMG.log

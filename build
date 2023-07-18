#! /bin/bash

profile="combined"
[ -n "$1" ] && profile="$1"

mods_combined="server main local_recording"
mods_server="server"
mods_main="main"

modsvar="mods_$profile"

img_combined="birdnetpi-amd64"
img_server="bnpi-server"
img_main="bnpi-site-main"

imgvar="img_$profile"

modules="${!modsvar}"
imgname="${!imgvar}"

set -x

TMPDIR=~/contbuild/bulk/tmp \
	buildah bud \
		-v /vol/pip-cache/birdnet:/home/pi/.cache/pip \
		-v $PWD/build-cache/apt:/var/cache/apt/archives \
		-v $PWD/build-cache/apt-lists:/var/lib/apt/lists \
		-v $PWD/build-cache/git:/home/pi/gitcache \
		-v $PWD/build-cache/caddy:/home/pi/.cache/caddy \
		--build-arg apt_proxy="http://fs2.lan:3142/" \
		--build-arg MODULES="$modules" \
		 --no-cache --force-rm=false \
		--tag $imgname:latest

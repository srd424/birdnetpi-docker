#! /bin/bash

set -e
set -x

OPTS=""

source buildopts/$OPTSFILE

if [ -n "$MODULES" ]; then
	OPTS="${OPTS} --build-arg \"MODULES=$MODULES\""
fi

IMG=$1

set -o pipefail

eval buildah bud \
	 --no-cache --force-rm=false \
	-f docker/Dockerfile.$IMG \
	--tag bnpi-$IMG:latest \
	$OPTS 2>&1 | tee logs/$IMG.log

#! /bin/bash

set -e
set -x

OPTS=""

source buildopts/$OPTSFILE

if [ -n "$MODULES" ]; then
	OPTS="${OPTS} --build-arg \"MODULES=$MODULES\""
fi

if [ -n "$BRANCH" ]; then
	OPTS="${OPTS} --build-arg \"BRANCH=$BRANCH\""
fi

IMG=$1

set -o pipefail

#	 --no-cache --force-rm=false \
#	--log-level debug \

eval buildah bud \
	-f docker/Dockerfile.$IMG \
	--tag bnpi-$IMG:latest \
	$OPTS 2>&1 | tee logs/$IMG.log

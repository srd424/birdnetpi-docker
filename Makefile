export OPTSFILE=sd
export BRANCH=modules

all: site-main server site-streamlit
#all: site-main server

site-main: .site-main

site-streamlit: .site-streamlit

server: .server

common: .common

.site-streamlit: .site-main docker/Dockerfile.site-streamlit build/final.sh build/build-final.sh
	MODULES=streamlit ./docker.sh site-streamlit
	touch .site-streamlit

.site-main: .common docker/Dockerfile.site-main build/final.sh build/build-final.sh
	MODULES="main" ./docker.sh site-main
	touch .site-main

.server: .common docker/Dockerfile.server build/final.sh build/build-final.sh
	MODULES=server ./docker.sh server
	touch .server

.build-common: .base docker/Dockerfile.build-common build/build-common.sh patches
	MODULES=common ./docker.sh build-common
	touch .build-common

.common: .base .build-common docker/Dockerfile.common build/common.sh static
	MODULES=common ./docker.sh common
	touch .common


.base: docker/Dockerfile.base build/base.sh
	./docker.sh base
	touch .base

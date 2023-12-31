export OPTSFILE=sd
export BRANCH=modules

all: site-main server site-streamlit
#all: site-main server

site-main: .site-main

site-streamlit: .site-streamlit

server: .server

common: .common

.site-streamlit: .site-common docker/Dockerfile.site-streamlit build/final.sh build/build-final.sh
	MODULES=streamlit ./docker.sh site-streamlit
	touch .site-streamlit

.site-main: .site-common docker/Dockerfile.site-main build/final.sh build/build-final.sh
	MODULES="main" ./docker.sh site-main
	touch .site-main

.server: .common docker/Dockerfile.server build/final.sh build/build-final.sh
	MODULES=server ./docker.sh server
	touch .server

.build-site-common: .build-common docker/Dockerfile.build-site-common build/build-site-common.sh patches
	MODULES=main ./docker.sh build-site-common
	touch .build-site-common

.build-common: .base docker/Dockerfile.build-common build/build-common.sh patches
	MODULES=common ./docker.sh build-common
	touch .build-common

.site-common: .common .build-site-common docker/Dockerfile.site-common build/site-common.sh static
	MODULES=main ./docker.sh site-common
	touch .site-common

.common: .base .build-common docker/Dockerfile.common build/common.sh static
	MODULES=common ./docker.sh common
	touch .common


.base: docker/Dockerfile.base build/base.sh
	./docker.sh base
	touch .base

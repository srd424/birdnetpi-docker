all: site-main server

site-main: .site-main

server: .server

common: .common

.site-main: .common docker/Dockerfile.site-main build/site-main.sh build/build-site-main.sh
	MODULES=main ./docker.sh site-main
	touch .site-main

.server: .common docker/Dockerfile.server build/server.sh build/build-server.sh
	MODULES=server ./docker.sh server
	touch .server

.build-common: .base docker/Dockerfile.build-common build/build-common.sh
	MODULES=common ./docker.sh build-common
	touch .build-common

.common: .base .build-common docker/Dockerfile.common build/common.sh
	MODULES=common ./docker.sh common
	touch .common


.base: docker/Dockerfile.base build/base.sh
	./docker.sh base
	touch .base
#
# =========================
#

FROM debian:bullseye-slim AS shared

ARG MODULES="all"
ARG apt_proxy
ARG aptopts="-y -qq --no-install-recommends -o Dpkg::options::=--force-confold"
ARG PYTHONDONTWRITEBYTECODE=1

RUN bash -c "echo \$PYTHONDONTWRITEBYTECODE"
RUN mkdir /etc/python3.9
RUN echo "import sys; sys.dont_write_bytecode = True" >/etc/python3.9/sitecustomize.py

RUN findmnt /var/cache/apt/archives && rm /etc/apt/apt.conf.d/docker-clean || true
RUN [ -n "$apt_proxy" ] && echo "Acquire::http::proxy \"$apt_proxy\";" >/etc/apt/apt.conf.d/02proxy || true


RUN apt-get update >/dev/null
RUN apt-get $aptopts install eatmydata

RUN dpkg-divert --local --rename /usr/bin/py3compile
RUN dpkg-divert --local --rename /usr/lib/python3.9/py_compile.py
RUN bash -c "d=/usr/lib/python3.9; mkdir -p \$d; touch \$d/py_compile.py"

RUN apt-get $aptopts install dbus sudo ca-certificates
RUN apt-get $aptopts install less iproute2 vim-tiny iputils-ping net-tools procps
RUN adduser --disabled-login --gecos "" pi
RUN adduser pi sudo
RUN apt-get $aptopts install curl jq python3-venv xz-utils

RUN bash -c "f=/usr/lib/python3.9/py_compile.py; rm \$f; \
	dpkg-divert --remove --local --rename \$f"

RUN rm -f /var/cache/apt/*.bin
RUN find / -xdev -name '*.pyc' -print0 | xargs -r -0 rm -v

#
# =========================
#

FROM shared AS build

ARG MODULES="all"
ARG aptopts="-y -qq --no-install-recommends -o Dpkg::options=--force-confold"
ARG PYTHONDONTWRITEBYTECODE=1

RUN apt-get $aptopts install git patch

# bind mounting onto /home/pi may create it early with wrong ownership
RUN chown -R pi:pi /home/pi

ARG FORK=srd424
ARG BRANCH=modules

RUN su -l pi -c "if [ -d /home/pi/gitcache/$FORK/git ]; then \
		git --git-dir /home/pi/gitcache/$FORK/git fetch;  \
		mkdir BirdNET-Pi; \
		git --git-dir /home/pi/gitcache/$FORK/git -C \$PWD/BirdNET-Pi checkout .;  \
		git --git-dir /home/pi/gitcache/$FORK/git -C \$PWD/BirdNET-Pi pull; \
	else \
		mkdir -p /home/pi/gitcache/$FORK; \
		git clone --separate-git-dir /home/pi/gitcache/$FORK/git -b $BRANCH --depth=1 https://github.com/srd424/BirdNET-Pi.git /home/pi/BirdNET-Pi;  \
	fi"
RUN curl -s 'https://patch-diff.githubusercontent.com/raw/mcguirepr89/BirdNET-Pi/pull/970.diff' | \
	patch -d /home/pi/BirdNET-Pi -p1
#RUN curl -s 'https://patch-diff.githubusercontent.com/raw/mcguirepr89/BirdNET-Pi/pull/974.diff' | \
#	patch -d /home/pi/BirdNET-Pi -p1

RUN mkdir -p /patches
ADD patches/04-override-config.diff /patches
#RUN patch -d /home/pi/BirdNET-Pi -p1 </patches/04-override-config.diff

#RUN curl -s 'https://patch-diff.githubusercontent.com/raw/MatthewBCooke/BirdNET-Pi/pull/13.diff' | \
#	patch -d /home/pi/BirdNET-Pi -p1

# static ffmpeg patch, incorporated
#RUN curl -s 'https://github.com/srd424/BirdNET-Pi/commit/221c225d390f3488abf27539448ea4b901ec2786.diff' | \
#	patch -d /home/pi/BirdNET-Pi -p1

# remote analysis server patch, incorporated
#RUN curl -s 'https://github.com/srd424/BirdNET-Pi/commit/1cbff6d1f57208d03389eb5cfd4dd065a7359449.diff' | \
#	patch -d /home/pi/BirdNET-Pi -p1

ADD patches/07-ffmpeg-opts.diff /patches
RUN patch -d /home/pi/BirdNET-Pi -p1 </patches/07-ffmpeg-opts.diff

RUN su -l pi -c " \
	cd ~/BirdNET-Pi; \
	python3 -m venv birdnet; \
	source ./birdnet/bin/activate; \
  	debarch=\"\$(dpkg --print-architecture)\"; \
  	reqd=\$HOME/BirdNET-Pi/reqs; \
	for mod in common $MODULES; do \
		reqf=\$reqd/\$mod-\$debarch.txt; \
		[ ! -e \$reqf ] && reqf=\$reqd/\$mod.txt; \
		[ ! -e \$reqf ] && continue; \
		echo \"installing python reqs from \$reqf\"; \
		pip3 install --no-compile -U -r \$reqf; \
	done"

RUN bash -c " \
	eval \$(grep PKGS_build /home/pi/BirdNET-Pi/scripts/install_services.sh); \
	apt-get -y install --no-install-recommends $PKGS_build"

RUN rm -f /var/cache/apt/*.bin
RUN find / -xdev -name '*.pyc' -print0 | xargs -r -0 rm -v

FROM shared AS final
ARG MODULES="all"
ARG aptopts="-qq -y --no-install-recommends"
ARG PYTHONDONTWRITEBYTECODE=1
RUN echo "modules is $MODULES"

ADD --chmod=0755 systemctl3.py /usr/bin/systemctl
RUN sed -i -e '1c#! /usr/bin/python3 -B' /usr/bin/systemctl

RUN apt-get $aptopts install cron

COPY --from=build /home/pi/BirdNET-Pi /home/pi/BirdNET-Pi
#RUN rm -r /home/pi/BirdNET-Pi/.git
#RUN findmnt /home/pi/gitcache || rm -r /home/pi/gitcache
RUN chown -R pi:pi /home/pi

#RUN echo INSTALL_PULSEAUDIO=false >/home/pi/BirdNET-Pi/birdnet.conf.override
#RUN echo INSTALL_FFMPEG=static >>/home/pi/BirdNET-Pi/birdnet.conf.override
RUN echo "MODULES_ENABLED=\"$MODULES\"" >>/home/pi/BirdNET-Pi/birdnet.conf.override
RUN cat /home/pi/BirdNET-Pi/birdnet.conf.override


RUN echo '%sudo ALL=(ALL) NOPASSWD: ALL' >/etc/sudoers.d/nopasswd
RUN echo '/usr/lib/x86_64-linux-gnu/libeatmydata.so.1' >>/etc/ld.so.preload

RUN bash -c "echo 'APT::Install-Recommends "false";' >/etc/apt/apt.conf.d/01no-recommends"

#RUN su -l pi -c "/home/pi/BirdNET-Pi/scripts/install_birdnet.sh"
RUN su -l pi -c "env my_dir=/home/pi/BirdNET-Pi /home/pi/BirdNET-Pi/scripts/install_config.sh"
RUN env HOME=/home/pi USER=pi my_dir=/home/pi/BirdNET-Pi MODULES_SKIP_BUILD=true /home/pi/BirdNET-Pi/scripts/install_services.sh
RUN su -l pi -c " \
	my_dir=/home/pi/BirdNET-Pi; \
	source \$my_dir/birdnet.conf; \
	mkdir -p \${RECS_DIR}; \
	cd \$my_dir/scripts; \
	./install_language_label_nm.sh -l \$DATABASE_LANG"

RUN bash -c 'f=BirdDB.txt;			d=/home/pi/BirdNET-Pi; rm -f $d/$f && ln -s /state/$f $d/$f'
RUN bash -c 'f=apprise.txt;		d=/home/pi/BirdNET-Pi; rm -f $d/$f && ln -s /state/$f $d/$f'
RUN bash -c 'f=birdnet.conf;		d=/home/pi/BirdNET-Pi; rm -f $d/$f && ln -s /state/$f $d/$f'
RUN bash -c 'f=exclude_species_list.txt;	d=/home/pi/BirdNET-Pi; rm -f $d/$f && ln -s /state/$f $d/$f'
RUN bash -c 'f=include_species_list.txt;	d=/home/pi/BirdNET-Pi; rm -f $d/$f && ln -s /state/$f $d/$f'
RUN bash -c 'f=birds.db;	d=/home/pi/BirdNET-Pi/scripts; rm -f $d/$f && ln -s /state/$f $d/$f'

RUN rm /etc/timezone

# slim down image

RUN bash -c " \
	for s in \
			birdnet_analysis.service birdnet_log.service birdnet_recording.service \
			birdnet_server.service birdnet_stats.service chart_viewer.service \
			custom_recording.service extraction.service livestream.service \
			spectrogram_viewer.service; \
			do \
		d=/etc/systemd/system/\${s}.d; \
		mkdir -p \$d; \
		echo -e \"[Service]\nEnvironment=PYTHONPYCACHEPREFIX=/home/pi/.cache/pycache\" > \
			\$d/pycache.conf; \
	done"


RUN rm -f /usr/local/lib/ffmpeg/ffprobe
RUN rm -f /home/pi/BirdNET-Pi/*.whl
RUN rm -f /home/pi/BirdNET-Pi/model/BirdNET_6K_GLOBAL_MODEL.tflite

RUN bash -c "if [ \"$MODULES\" = server ]; then rm -f /home/pi/BirdNET-Pi/scripts/gotty; fi"

RUN findmnt /home/pi/.cache/pip || rm -r /home/pi/.cache/pip
RUN rm -f /var/cache/apt/*.bin

RUN bash -c "d=/etc/systemd/system//php7.4-fpm.service.d; mkdir \$d && echo -e '[Service]\nExecStartPre=/bin/bash -c \"mkdir /run/php; chown www-data:www-data /run/php; chmod 0755 /run/php\"' >\$d/mkdir.conf"

RUN bash -c "if [ -e /usr/bin/caddy ]; then \
		sed -i -r \
			-e 's|^ExecStart=(.*)$|ExecStart=/sbin/capsh --user=caddy -- -c \"\1\"|' \
			-e '/^(User|Group)/d' \
			/lib/systemd/system/caddy.service; \
		setcap cap_net_bind_service=+ep /usr/bin/caddy; \
	fi"

RUN find / -xdev -name '*.pyc' -print0 | xargs -r -0 rm -v
RUN echo "" >/etc/python3.9/sitecustomize.py

EXPOSE 80
ENTRYPOINT ["/usr/bin/systemctl"]

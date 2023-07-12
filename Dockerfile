#ctr=$(buildah from debian:bullseye)

FROM debian:bullseye-slim AS build

ARG apt_proxy

#RUN bash -c "[ -n \"$apt_proxy\" ] && echo \"Acquire::http::proxy \\\"http://$apt_proxy\\\";\" >/etc/apt/apt.conf.d/02proxy"
RUN findmnt /var/cache/apt/archives && rm /etc/apt/apt.conf.d/docker-clean || true
RUN [ -n "$apt_proxy" ] && echo "Acquire::http::proxy \"$apt_proxy\";" >/etc/apt/apt.conf.d/02proxy || true
RUN apt-get update
RUN apt-get -y install --no-install-recommends eatmydata
RUN apt-get -y install --no-install-recommends systemd dbus sudo ca-certificates
RUN apt-get -y install --no-install-recommends less iproute2 vim-tiny iputils-ping net-tools
RUN systemctl enable systemd-resolved
RUN adduser --disabled-login --gecos "" pi
RUN adduser pi sudo
RUN apt-get -y install --no-install-recommends curl git jq python3-venv patch cron

# bind mounting onto /home/pi may create it early with wrong ownership
RUN chown -R pi:pi /home/pi

RUN su -l pi -c "if [ -d /home/pi/gitcache/git ]; then \
		git --git-dir /home/pi/gitcache/git fetch;  \
		mkdir BirdNET-Pi; \
		git --git-dir /home/pi/gitcache/git -C \$PWD/BirdNET-Pi checkout .;  \
	else \
		mkdir -p /home/pi/gitcache; \
		git clone --separate-git-dir /home/pi/gitcache/git -b debian --depth=1 https://github.com/MatthewBCooke/BirdNET-Pi.git /home/pi/BirdNET-Pi;  \
	fi"
RUN curl -s 'https://patch-diff.githubusercontent.com/raw/mcguirepr89/BirdNET-Pi/pull/970.diff' | \
	patch -d /home/pi/BirdNET-Pi -p1
RUN curl -s 'https://patch-diff.githubusercontent.com/raw/mcguirepr89/BirdNET-Pi/pull/974.diff' | \
	patch -d /home/pi/BirdNET-Pi -p1

RUN mkdir -p /patches
ADD patches/04-override-config.diff /patches
RUN patch -d /home/pi/BirdNET-Pi -p1 </patches/04-override-config.diff

RUN curl -s 'https://patch-diff.githubusercontent.com/raw/MatthewBCooke/BirdNET-Pi/pull/13.diff' | \
	patch -d /home/pi/BirdNET-Pi -p1

RUN curl -s 'https://github.com/srd424/BirdNET-Pi/commit/221c225d390f3488abf27539448ea4b901ec2786.diff' | \
	patch -d /home/pi/BirdNET-Pi -p1

FROM debian:bullseye-slim
ARG apt_proxy
RUN echo proxy $apt_proxy
RUN findmnt /var/cache/apt/archives && rm /etc/apt/apt.conf.d/docker-clean || true
RUN [ -n "$apt_proxy" ] && echo "Acquire::http::proxy \"$apt_proxy\";" >/etc/apt/apt.conf.d/02proxy || true

RUN apt-get update
RUN apt-get -y install --no-install-recommends eatmydata
RUN apt-get -y install --no-install-recommends systemd dbus sudo ca-certificates
RUN apt-get -y install --no-install-recommends less iproute2 vim-tiny iputils-ping net-tools
RUN systemctl enable systemd-resolved
RUN adduser --disabled-login --gecos "" pi
RUN adduser pi sudo
RUN apt-get -y install --no-install-recommends curl jq python3-venv patch cron

COPY --from=build /home/pi/BirdNET-Pi /home/pi/BirdNET-Pi
#RUN rm -r /home/pi/BirdNET-Pi/.git
#RUN findmnt /home/pi/gitcache || rm -r /home/pi/gitcache
RUN chown -R pi:pi /home/pi

RUN echo INSTALL_PULSEAUDIO=false >/home/pi/BirdNET-Pi/birdnet.conf.override
RUN echo INSTALL_FFMPEG=static >>/home/pi/BirdNET-Pi/birdnet.conf.override

RUN echo '%sudo ALL=(ALL) NOPASSWD: ALL' >/etc/sudoers.d/nopasswd
RUN echo '/usr/lib/x86_64-linux-gnu/libeatmydata.so.1' >>/etc/ld.so.preload

RUN su -l pi -c "/home/pi/BirdNET-Pi/scripts/install_birdnet.sh"


RUN bash -c 'f=BirdDB.txt;			d=/home/pi/BirdNET-Pi; rm -f $d/$f && ln -s /state/$f $d/$f'
RUN bash -c 'f=apprise.txt;		d=/home/pi/BirdNET-Pi; rm -f $d/$f && ln -s /state/$f $d/$f'
RUN bash -c 'f=birdnet.conf;		d=/home/pi/BirdNET-Pi; rm -f $d/$f && ln -s /state/$f $d/$f'
RUN bash -c 'f=exclude_species_list.txt;	d=/home/pi/BirdNET-Pi; rm -f $d/$f && ln -s /state/$f $d/$f'
RUN bash -c 'f=include_species_list.txt;	d=/home/pi/BirdNET-Pi; rm -f $d/$f && ln -s /state/$f $d/$f'
RUN bash -c 'f=birds.db;	d=/home/pi/BirdNET-Pi/scripts; rm -f $d/$f && ln -s /state/$f $d/$f'

RUN rm /etc/timezone

# slim down image

RUN rm -f /usr/local/lib/ffmpeg/ffprobe
RUN rm -f /home/pi/BirdNET-Pi/*.whl
RUN rm -f /home/pi/BirdNET-Pi/models/BirdNET_6K_GLOBAL_MODEL.tflite

RUN apt-get -y remove g++-10 cpp-10 gcc-10 cmake libstdc++-10-dev libc6-dev libasan6 libtsan0 cmake-data binutils-x86-64-linux-gnu linux-libc-dev swig4.0 manpages-dev liblsan0 libubsan1


RUN findmnt /home/pi/.cache/pip || rm -r /home/pi/.cache/pip
RUN rm -f /var/cache/apt/*.bin


EXPOSE 80
ENTRYPOINT ["/bin/systemd"]

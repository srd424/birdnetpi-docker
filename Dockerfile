#ctr=$(buildah from debian:bullseye)
FROM debian:bullseye
RUN apt-get update
RUN apt-get -y install --no-install-recommends eatmydata
RUN apt-get -y install --no-install-recommends systemd dbus sudo udev ca-certificates
RUN apt-get -y install --no-install-recommends less iproute2 vim-tiny iputils-ping net-tools
RUN systemctl enable systemd-resolved
RUN adduser --disabled-login --gecos "" pi
RUN adduser pi sudo
RUN apt-get -y install --no-install-recommends curl git jq python3-venv patch cron
RUN su -l pi -c "git clone -b debian --depth=1 https://github.com/MatthewBCooke/BirdNET-Pi.git /home/pi/BirdNET-Pi"
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

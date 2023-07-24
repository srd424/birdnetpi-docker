main () {
	apt-get $aptopts install git patch

	# bind mounting onto /home/pi may create it early with wrong ownership
	chown -R pi:pi /home/pi

	su -l pi -c "if [ -d /home/pi/gitcache/$FORK/git ]; then \
			git --git-dir /home/pi/gitcache/$FORK/git fetch;  \
			mkdir BirdNET-Pi; \
			git --git-dir /home/pi/gitcache/$FORK/git -C \$PWD/BirdNET-Pi checkout .;  \
			git --git-dir /home/pi/gitcache/$FORK/git -C \$PWD/BirdNET-Pi pull; \
		else \
			mkdir -p /home/pi/gitcache/$FORK; \
			git clone --separate-git-dir /home/pi/gitcache/$FORK/git -b $BRANCH --depth=1 https://github.com/srd424/BirdNET-Pi.git /home/pi/BirdNET-Pi;  \
		fi"

	apply_patches

	source /home/pi/BirdNET-Pi/scripts/set_modules.sh
	source /home/pi/BirdNET-Pi/scripts/modules_info.sh
	source /home/pi/BirdNET-Pi/scripts/install_caddy.sh
	apt-get -y install --no-install-recommends $PKGS_build
	filter_pkg CADDY caddy
	$NEED_CADDY && HOME=/home/pi install_caddy_build_pre
	apt-get -y update && apt-get -y upgrade
	$NEED_CADDY && HOME=/home/pi install_caddy_build

	cat >>/home/pi/BirdNET-Pi/reqs/common.txt <<EOF
attrs
audioread
click
decorator
iniconfig
joblib
lazy-loader
msgpack
numba
numpy
packaging
pluggy
pooch
py
pytest
requests
scikit-learn
scipy
soundfile
soxr
tomli
typing-extensions
EOF
	su -l pi -c "/bin/bash /build-scripts/pip.sh"

	rm -r -f /patches

	rm -f /var/cache/apt/*.bin
	find / -xdev -name '*.pyc' -print0 | xargs -r -0 rm -v
}

apply_patches () {

	su -l pi -c " \
		curl -s 'https://patch-diff.githubusercontent.com/raw/mcguirepr89/BirdNET-Pi/pull/970.diff' | \
			patch -d /home/pi/BirdNET-Pi -p1; \
			"
	#RUN curl -s 'https://patch-diff.githubusercontent.com/raw/mcguirepr89/BirdNET-Pi/pull/974.diff' | \
	#	patch -d /home/pi/BirdNET-Pi -p1

	#RUN patch -d /home/pi/BirdNET-Pi -p1 </patches/04-override-config.diff

	#RUN curl -s 'https://patch-diff.githubusercontent.com/raw/MatthewBCooke/BirdNET-Pi/pull/13.diff' | \
	#	patch -d /home/pi/BirdNET-Pi -p1

	# static ffmpeg patch, incorporated
	#RUN curl -s 'https://github.com/srd424/BirdNET-Pi/commit/221c225d390f3488abf27539448ea4b901ec2786.diff' | \
	#	patch -d /home/pi/BirdNET-Pi -p1

	# remote analysis server patch, incorporated
	#RUN curl -s 'https://github.com/srd424/BirdNET-Pi/commit/1cbff6d1f57208d03389eb5cfd4dd065a7359449.diff' | \
	#	patch -d /home/pi/BirdNET-Pi -p1

	su -l pi -c " \
		patch -d /home/pi/BirdNET-Pi -p1 </patches/07-ffmpeg-opts.diff \
		"
}

main "$@"


set -e
set -x

script=/home/pi/BirdNET-Pi/scripts/install_services.sh
sed -i -e '/^chown_things$/d' $script
sed -i -e '/^[ \t]*chmod -R g+rw \$my_dir/d' $script

env HOME=/home/pi USER=pi my_dir=/home/pi/BirdNET-Pi \
	MODULES_SKIP_BUILD=true \
	MODULES_ENABLED="$MODULES" \
	DEBIAN_FRONTEND="noninteractive" \
	$script

rm -f /usr/local/lib/ffmpeg/ffprobe

source /build-scripts/cleanup.sh

f=birdnet.conf;		d=/home/pi/BirdNET-Pi; rm -f $d/$f && ln -s /state/$f $d/$f

#rm -f /home/pi/BirdNET-Pi/scripts/gotty
echo "" >/etc/python3.9/sitecustomize.py

rm -r -f /state/*

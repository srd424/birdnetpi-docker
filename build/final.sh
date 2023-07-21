
set -e
set -x

env HOME=/home/pi USER=pi my_dir=/home/pi/BirdNET-Pi \
	MODULES_SKIP_BUILD=true \
	MODULES_ENABLED="$MODULES" \
	/home/pi/BirdNET-Pi/scripts/install_services.sh

rm -f /usr/local/lib/ffmpeg/ffprobe

findmnt /home/pi/.cache/pip || rm -r /home/pi/.cache/pip
rm -f /var/cache/apt/*.bin

find / -xdev -name '*.pyc' -print0 | xargs -r -0 rm -v

f=birdnet.conf;		d=/home/pi/BirdNET-Pi; rm -f $d/$f && ln -s /state/$f $d/$f

#rm -f /home/pi/BirdNET-Pi/scripts/gotty
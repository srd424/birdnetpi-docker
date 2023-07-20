
set -e
set -x

sed -i -e '1c#! /usr/bin/python3 -B' /usr/bin/systemctl

#RUN rm -r /home/pi/BirdNET-Pi/.git
#RUN findmnt /home/pi/gitcache || rm -r /home/pi/gitcache
chown -R pi:pi /home/pi

#RUN echo INSTALL_PULSEAUDIO=false >/home/pi/BirdNET-Pi/birdnet.conf.override
#RUN echo INSTALL_FFMPEG=static >>/home/pi/BirdNET-Pi/birdnet.conf.override
echo "MODULES_ENABLED=\"$MODULES\"" >>/home/pi/BirdNET-Pi/birdnet.conf.override
cat /home/pi/BirdNET-Pi/birdnet.conf.override


echo '%sudo ALL=(ALL) NOPASSWD: ALL' >/etc/sudoers.d/nopasswd
echo '/usr/lib/x86_64-linux-gnu/libeatmydata.so.1' >>/etc/ld.so.preload

bash -c "echo 'APT::Install-Recommends "false";' >/etc/apt/apt.conf.d/01no-recommends"

#RUN su -l pi -c "/home/pi/BirdNET-Pi/scripts/install_birdnet.sh"
su -l pi -c "env my_dir=/home/pi/BirdNET-Pi /home/pi/BirdNET-Pi/scripts/install_config.sh"
env HOME=/home/pi USER=pi my_dir=/home/pi/BirdNET-Pi MODULES_SKIP_BUILD=true /home/pi/BirdNET-Pi/scripts/install_services.sh
su -l pi -c " \
	my_dir=/home/pi/BirdNET-Pi; \
	source \$my_dir/birdnet.conf; \
	mkdir -p \${RECS_DIR}; \
	cd \$my_dir/scripts; \
	./install_language_label_nm.sh -l \$DATABASE_LANG"

f=BirdDB.txt;			d=/home/pi/BirdNET-Pi; rm -f $d/$f && ln -s /state/$f $d/$f
f=apprise.txt;		d=/home/pi/BirdNET-Pi; rm -f $d/$f && ln -s /state/$f $d/$f
f=exclude_species_list.txt;	d=/home/pi/BirdNET-Pi; rm -f $d/$f && ln -s /state/$f $d/$f
f=include_species_list.txt;	d=/home/pi/BirdNET-Pi; rm -f $d/$f && ln -s /state/$f $d/$f
f=birds.db;	d=/home/pi/BirdNET-Pi/scripts; rm -f $d/$f && ln -s /state/$f $d/$f

#not birdnet.conf - breaks later installs
#f=birdnet.conf;		d=/home/pi/BirdNET-Pi; rm -f $d/$f && ln -s /state/$f $d/$f

rm /etc/timezone

for s in \
		birdnet_analysis.service birdnet_log.service birdnet_recording.service \
		birdnet_server.service birdnet_stats.service chart_viewer.service \
		custom_recording.service extraction.service livestream.service \
		spectrogram_viewer.service; \
		do
	d=/etc/systemd/system/${s}.d
	mkdir -p $d
	echo -e "[Service]\nEnvironment=PYTHONPYCACHEPREFIX=/home/pi/.cache/pycache" > \
		$d/pycache.conf
done


rm -f /usr/local/lib/ffmpeg/ffprobe
rm -f /home/pi/BirdNET-Pi/*.whl
rm -f /home/pi/BirdNET-Pi/model/BirdNET_6K_GLOBAL_MODEL.tflite

findmnt /home/pi/.cache/pip || rm -r /home/pi/.cache/pip
rm -f /var/cache/apt/*.bin

find / -xdev -name '*.pyc' -print0 | xargs -r -0 rm -v

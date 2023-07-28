#! /bin/bash

set -x

[ -d /state ] || exit 1

(
	flock -w 30 9 || exit 1
	date

	chown -R pi:pi /state

	cd /state

	if ! [ -e birdnet.conf ]; then
		#cp -av /home/pi/BirdNET-Pi/birdnet.conf-defaults birdnet.conf
		su -l pi -c "my_dir=/home/pi/BirdNET-Pi /usr/local/bin/install_config.sh"
		chown pi:pi birdnet.conf
	fi
	[ -e birds.db ] || su -l pi -c /usr/local/bin/createdb.sh	
	for f in BirdDB.txt apprise.txt exclude_species_list.txt include_species_list.txt; do
		[ -e $f ] || :>$f
		chown pi:pi $f
	done
	exit 0
) 9>/state/.lock

if [ $? -eq 1 ]; then
	echo "Couldn't lock /state directory" >&2
	exit 2
fi

exit 0

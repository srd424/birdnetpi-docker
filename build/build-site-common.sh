set -ex

main () {
	cat /build-scripts/common-pip.txt >>/home/pi/BirdNET-Pi/reqs/common.txt

	su -l pi -c "env MODULES=\"$MODULES\" /bin/bash /build-scripts/pip.sh"

	rm -r -f /patches

	rm -f /var/cache/apt/*.bin
	find / -xdev -name '*.pyc' -print0 | xargs -r -0 rm -v
}

main "$@"

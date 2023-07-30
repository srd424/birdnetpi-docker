set -ex

main () {

	su -l pi -c "env MODULES=\"$MODULES\" /bin/bash /build-scripts/pip.sh"

	rm -f /var/cache/apt/*.bin
	find / -xdev -name '*.pyc' -print0 | xargs -r -0 rm -v
}

main "$@"

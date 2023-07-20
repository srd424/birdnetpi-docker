bash -c "echo $PYTHONDONTWRITEBYTECODE"
mkdir /etc/python3.9
echo "import sys; sys.dont_write_bytecode = True" >/etc/python3.9/sitecustomize.py

findmnt /var/cache/apt/archives && rm /etc/apt/apt.conf.d/docker-clean || true
[ -n "$apt_proxy" ] && echo "Acquire::http::proxy \"$apt_proxy\";" >/etc/apt/apt.conf.d/02proxy || true


apt-get update >/dev/null
apt-get $aptopts install eatmydata

dpkg-divert --local --rename /usr/bin/py3compile
dpkg-divert --local --rename /usr/lib/python3.9/py_compile.py
bash -c "d=/usr/lib/python3.9; mkdir -p \$d; touch \$d/py_compile.py"

apt-get $aptopts install dbus sudo ca-certificates
apt-get $aptopts install less iproute2 vim-tiny iputils-ping net-tools procps
adduser --disabled-login --gecos "" pi
adduser pi sudo
apt-get $aptopts install curl jq python3-venv xz-utils

bash -c "f=/usr/lib/python3.9/py_compile.py; rm \$f; \
	dpkg-divert --remove --local --rename \$f"

rm -f /var/cache/apt/*.bin
find / -xdev -name '*.pyc' -print0 | xargs -r -0 rm -v


set -e
set -x

cp -avuT /bn /home/pi/BirdNET-Pi/birdnet
rm -r /bn

findmnt /home/pi/.cache/pip || rm -r /home/pi/.cache/pip
rm -f /var/cache/apt/*.bin

find / -xdev -name '*.pyc' -print0 | xargs -r -0 rm -v

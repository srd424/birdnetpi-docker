export PYTHONDONTWRITEBYTECODE=1 
cat /etc/python3.9/sitecustomize.py
cd ~/BirdNET-Pi
if [ ! -d birdnet/bin ]; then
	python3 -m venv birdnet
fi
source ./birdnet/bin/activate

debarch="$(dpkg --print-architecture)"
reqd=$HOME/BirdNET-Pi/reqs
allreq=`mktemp`
for mod in common $MODULES; do
	reqf=$reqd/$mod-$debarch.txt
	[ ! -e $reqf ] && reqf=$reqd/$mod.txt
	[ ! -e $reqf ] && continue
	echo "merging in python reqs from $reqf"
	cat $reqf >>$allreq
done
allrequ=`mktemp`
cat $allreq | sort | uniq >$allrequ
pip3 install --no-compile -r $allrequ

# birdnetpi-docker
Docker adaptation of BirdNET-Pi

Expects a state directory mounted on `/state` containing:
BirdDB.txt
apprise.txt
birdnet.conf
exclude_species_list.txt
include_species_list.txt
birds.db

Mounting a filesystem large enough to store recordings on `/home/pi/BirdSongs` is probably also sensible.

Example podman command line:
`podman run --name birdnet -p 80 --mount=type=bind,src=$HOME/src/birdnet.state,dst=/state -t -i birdnetpi-docker-test /bin/systemd`

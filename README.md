# birdnetpi-docker
Docker adaptation of [BirdNET-Pi](https://github.com/mcguirepr89/BirdNET-Pi)

Expects a state directory mounted on `/state` containing:
- `BirdDB.txt`
- `apprise.txt`
- `birdnet.conf`
- `exclude_species_list.txt`
- `include_species_list.txt`
- `birds.db`

Mounting a filesystem large enough to store recordings on `/home/pi/BirdSongs` is probably also sensible.

Example podman command line:
```
podman run --name birdnet -p 8080:80 -v $HOME/src/birdnet.state:/state -t -i ghcr.io/srd424/birdnetpi-amd64
```
I haven't yet tested this in docker, rumour has it is less friendly to containers using systemd, at least by default. Bug reports welcome!

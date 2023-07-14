# birdnetpi-docker

Docker adaptation of [BirdNET-Pi](https://github.com/mcguirepr89/BirdNET-Pi) - currently x86-64 only, but porting back to arm shouldn't be crazy hard.

## Installation

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
podman run --name birdnet -p 8080:80 \
  -v $HOME/birdnet.state:/state \
  -v $HOME/BirdSongs:/home/pi/BirdSongs \
  ghcr.io/srd424/birdnetpi-amd64:latest
```
Whereas for docker you need to explicitly add the CAP_NET_BIND_SERVICE so caddy can bind to port 80:
```
docker run  --name birdnet -p 8080:80 \
  --cap-add=cap_net_bind_service \
  -v $HOME/birdnet.state:/state \
  -v $HOME/BirdSongs:/home/pi/BirdSongs \
  localhost/birdnetpi-amd64:latest
```

## Changelog ##
**12-Jul-2023:** I'm now running this 'rootfully' with podman as my main, 'live' BirdNET-Pi install, so we'll see how it goes.

**13-Jul-2023:** Removed systemd to make it work sanely with docker; this is now merged into main branch and package, and again, I'm running it 'in prod' with no problems .. yet.


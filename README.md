# birdnetpi-docker

Docker adaptation of [BirdNET-Pi](https://github.com/mcguirepr89/BirdNET-Pi) - currently x86-64 only, but porting back to arm shouldn't be crazy hard.
This is now split into three images - one for the analysis server, one for the main web application and miscellaneous tasks, and one for the streamlit based data visualization component.

## Basic installation

The images all need a 'state' directory mounted on `/state`, in which config files and the detections database can be stored. In more recent images this should automatically get populated if necessary on start-up. The directory should end up containing:
- `BirdDB.txt`
- `apprise.txt`
- `birdnet.conf`
- `exclude_species_list.txt`
- `include_species_list.txt`
- `birds.db`
  
These can be copied in from a previous installation if desired. At the moment configuration through the web application is broken (I think), so you will need to edit `birdnet.conf` before (re)starting the containers. In particular you need to set `ANALYSIS_SERVER` in the config file to the hostname / IP address where the analysis server container can be reached (this should probably be an environment variable instead.)

You will also need to mount a filesystem large enough to store recordings on `/home/pi/BirdSongs` for the `server` and `site-main` containers.

Example podman command lines:
```
podman run --name bnpi-site-main -p 8080:80 \
  -v $HOME/birdnet.state:/state -v $HOME/BirdSongs:/home/pi/BirdSongs \
  ghcr.io/srd424/bnpi-site-main:amd64

podman run --name bnpi-server -p 5050:5050 \
  -v $HOME/birdnet.state:/state -v $HOME/BirdSongs:/home/pi/BirdSongs \
  ghcr.io/srd424/bnpi-server:amd64
```

## Using the streamlit app ##

If you want the advanced "Species stats" data visualization web app that uses streamlit, you need the `bnpi-site-streamlit`image:
```
podman run --name bnpi-server -p 8051:8051 \
  -v $HOME/birdnet.state:/state \
  ghcr.io/srd424/bnpi-site-streamlit:amd64
```
You then need to set the `BNPI_STREAMLIT` environment variable to the host/IP where it can be reached when starting the main site container:
```
podman run --name bnpi-site-main -p 8080:80 \
  -v $HOME/birdnet.state:/state -v $HOME/BirdSongs:/home/pi/BirdSongs \
  -e BNPI_STREAMLIT=my-server.lan:8501 \
  ghcr.io/srd424/bnpi-site-main:amd64
```

## Using docker instead of podman ##
With docker you need to explicitly add the `CAP_NET_BIND_SERVICE` capability when running the main site container, so caddy can bind to port 80:
```
docker run  --name bnpi-site-main -p 8080:80 \
  -v $HOME/birdnet.state:/state -v $HOME/BirdSongs:/home/pi/BirdSongs \
  --cap-add=cap_net_bind_service ghcr.io/srd424/bnpi-site-main:amd64
```

## Image size ##

These images share several layers to avoid duplicating on disk some large python packages etc that are used by multiple images. The apparent total size of all three images is current ~ 2.5GB, but in reality they should only use up ~ 1.3GB because of this. There is some more work that could theoretically be done here, but it would probably involve some nasty hacks so may not be worth it.

## Changelog ##

**14-Aug-2023:** silly/nasty security bug where the caddy config wasn't being generated using the set password. Some of the php scripts check this again anyway, but things like the underlying `/stream` URL for the live stream audio weren't protected. Fixed.

**29-Jul-2023:** the streamlit analysis app ("Species Stats") now works again.

**28-Jul-2023:** these images are now "modularized", see [this discussion thread](https://github.com/mcguirepr89/BirdNET-Pi/discussions/984).

**13-Jul-2023:** Removed systemd to make it work sanely with docker; this is now merged into main branch and package, and again, I'm running it 'in prod' with no problems .. yet.

**12-Jul-2023:** I'm now running this 'rootfully' with podman as my main, 'live' BirdNET-Pi install, so we'll see how it goes.



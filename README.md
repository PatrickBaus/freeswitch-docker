[![GitHub release](https://img.shields.io/github/release/PatrickBaus/freeswitch-docker.svg)](https://github.com/PatrickBaus/freeswitch-docker/releases/latest)
[![Check for new release of FreeSWITCH](https://github.com/PatrickBaus/freeswitch-docker/actions/workflows/updater_freeswitch.yml/badge.svg)](https://github.com/PatrickBaus/freeswitch-docker/actions/workflows/updater_freeswitch.yml)
[![Check for new release of Sofia](https://github.com/PatrickBaus/freeswitch-docker/actions/workflows/updater_sofia.yml/badge.svg)](https://github.com/PatrickBaus/freeswitch-docker/actions/workflows/updater_sofia.yml)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)](https://github.com/PatrickBaus/freeswitch-docker/pkgs/container/freeswitch-docker)
# FreeSWTICH Docker container
This is an inofficial Docker file for [FreeSWITCH](https://signalwire.com/freeswitch). There currently is no official Docker container available from Signalwire except for [safarov/freeswitch](https://hub.docker.com/r/safarov/freeswitch) which has not been updated for years and is currently stuck at version 1.6. This container tracks the official releases.

## Contents
- [Introduction](#introduction)
- [Installation](#installation)
- [Versioning](#versioning)
- [Authors](#authors)
- [License](#license)

## Introduction
This Docker container is based on [Alpine Linux](https://alpinelinux.org/) instead of the Debian base image used by the [example Dockerfiles](https://github.com/signalwire/freeswitch#build-from-source). The container, in contrast to the default [FreeSWITCH](https://signalwire.com/freeswitch) build, does not contain `mod_av` and `mod_signalwire`.

## Installation
The container requires a data volume to store the configuration. [FreeSWITCH](https://signalwire.com/freeswitch) also requires port forwarding of (possibly) a large number of ports. The ports required can be found in the [FreeSWITCH documentation](https://developer.signalwire.com/freeswitch/FreeSWITCH-Explained/Networking/Firewall_1048908/), but due to the nature of RTP, the large number of required ports pose an [issue with Docker](https://github.com/moby/moby/issues/11185). It is therefore recommended to use `host` networking mode with this image.

The container can be started via Docker using the following command, but it is recommended to use [Docker Compose](https://docs.docker.com/compose/) instead

#### Docker
```bash
docker run -d --net=host --cap-add SYS_NICE -v $(pwd)/configuration:/etc/freeswitch ghcr.io/patrickbaus/freeswitch-docker
```

The `SYS_NICE` capability allows [FreeSWITCH](https://signalwire.com/freeswitch) to adjust its niceness to improve real-time functionality.

#### Docker compose
An example [docker-compose.yml](docker-compose.yml) file can be found in the repository and below.

```yaml
services:
  freeswitch:
    image: ghcr.io/patrickbaus/freeswitch-docker
    container_name: freeswitch
    restart: always
    cap_add:  # Enable RT features
      - SYS_NICE
    network_mode: "host"
    volumes:
      - '/mnt/docker/freeswitch/configs/:/etc/freeswitch/'
      - '/mnt/docker/freeswitch/logs/:/var/log/freeswitch/'
```

This compose file mounts two volumes into the container, one for the logs and the other for the config files. It also uses `host` mode for networking and enables `SYS_NICE` capabilities.

## Versioning
I follow the [FreeSWITCH releases](https://github.com/signalwire/freeswitch/releases) for version numbering. For the versions available, see the [tags](../../tags) available for this repository.

## Authors
* **Patrick Baus** - *Initial work* - [PatrickBaus](https://github.com/PatrickBaus)

## License
This project is licensed under the GPL v3 license - see the [LICENSE](LICENSE) file for details.

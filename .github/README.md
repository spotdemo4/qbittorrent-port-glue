# qbittorrent port glue

[![check](https://img.shields.io/github/actions/workflow/status/spotdemo4/qbittorrent-port-glue/check.yaml?branch=main&logo=github&logoColor=%23bac2de&label=check&labelColor=%23313244)](https://github.com/spotdemo4/qbittorrent-port-glue/actions/workflows/check.yaml/)
[![vulnerable](https://img.shields.io/github/actions/workflow/status/spotdemo4/qbittorrent-port-glue/vulnerable.yaml?branch=main&logo=github&logoColor=%23bac2de&label=vulnerable&labelColor=%23313244)](https://github.com/spotdemo4/qbittorrent-port-glue/actions/workflows/vulnerable.yaml)
[![nix](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2Fspotdemo4%2Fqbittorrent-port-glue%2Frefs%2Fheads%2Fmain%2Fflake.lock&query=%24.nodes.nixpkgs.original.ref&logo=nixos&logoColor=%23bac2de&label=channel&labelColor=%23313244&color=%234d6fb7)](https://nixos.org/)
[![python](<https://img.shields.io/badge/dynamic/regex?url=https%3A%2F%2Fraw.githubusercontent.com%2Fspotdemo4%2Fqbittorrent-port-glue%2Frefs%2Fheads%2Fmain%2F.python-version&search=(.*)&logo=python&logoColor=%23bac2de&label=version&labelColor=%23313244&color=%23306998>)](https://www.python.org/downloads/)

keeps qbittorrent's listening port synced with a port from a file

## use

### environment

| Variable         | Description                  | Example                           |
| ---------------- | ---------------------------- | --------------------------------- |
| QBITTORRENT_HOST | qBittorrent WebUI Host       | `https://qbittorrent.example.com` |
| QBITTORRENT_PORT | qBittorrent WebUI Port       | `8185`                            |
| QBITTORRENT_USER | qBittorrent WebUI Username   | `admin`                           |
| QBITTORRENT_PASS | qBittorrent WebUI Password   | `example`                         |
| PORT_FILE        | Path to file containing port | `/tmp/port.txt`                   |
| LOG_LEVEL        | Verbosity of logs            | `INFO`                            |

### docker

```elm
docker run \
    -e QBITTORRENT_HOST=https://qbittorrent.example.com \
    -e QBITTORRENT_PORT=8185 \
    -e QBITTORRENT_USER=admin \
    -e QBITTORRENT_PASS=example \
    -e PORT_FILE=/tmp/port.txt \
    -v "/tmp/port.txt:/tmp/port.txt" \
    ghcr.io/spotdemo4/qbittorrent-port-glue:0.1.1
```

#### docker-compose.yaml

```yaml
name: qbittorrent-port-glue
services:
  qbittorrent-port-glue:
    environment:
      - QBITTORRENT_HOST=https://qbittorrent.example.com
      - QBITTORRENT_PORT=8185
      - QBITTORRENT_USER=admin
      - QBITTORRENT_PASS=example
      - PORT_FILE=/tmp/port.txt
    volumes:
      - /tmp/port.txt:/tmp/port.txt
    image: ghcr.io/spotdemo4/qbittorrent-port-glue:0.1.1
```

### nix

```elm
nix run github:spotdemo4/qbittorrent-port-glue
```

### uv

```elm
uvx git+https://github.com/spotdemo4/qbittorrent-port-glue
```

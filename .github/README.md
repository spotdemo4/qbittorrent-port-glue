# qbittorrent port glue

[![check](https://img.shields.io/github/actions/workflow/status/spotdemo4/qbittorrent-port-glue/check.yaml?branch=main&logo=github&logoColor=%23bac2de&label=check&labelColor=%23313244)](https://github.com/spotdemo4/qbittorrent-port-glue/actions/workflows/check.yaml/)
[![vulnerable](https://img.shields.io/github/actions/workflow/status/spotdemo4/qbittorrent-port-glue/vulnerable.yaml?branch=main&logo=github&logoColor=%23bac2de&label=vulnerable&labelColor=%23313244)](https://github.com/spotdemo4/qbittorrent-port-glue/actions/workflows/vulnerable.yaml)
[![nix](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2Fspotdemo4%2Fqbittorrent-port-glue%2Frefs%2Fheads%2Fmain%2Fflake.lock&query=%24.nodes.nixpkgs.original.ref&logo=nixos&logoColor=%23bac2de&label=channel&labelColor=%23313244&color=%234d6fb7)](https://nixos.org/)
[![python](<https://img.shields.io/badge/dynamic/regex?url=https%3A%2F%2Fraw.githubusercontent.com%2Fspotdemo4%2Fqbittorrent-port-glue%2Frefs%2Fheads%2Fmain%2F.python-version&search=(.*)&logo=python&logoColor=%23bac2de&label=version&labelColor=%23313244&color=%23306998>)](https://www.python.org/downloads/)

glues qbittorrent's port to a file

## use

### docker

```elm
docker run ghcr.io/spotdemo4/qbittorrent-port-glue:0.1.0
```

### nix

```elm
nix run github:spotdemo4/qbittorrent-port-glue
```

### uv

```elm
uvx git+https://github.com/spotdemo4/qbittorrent-port-glue
```

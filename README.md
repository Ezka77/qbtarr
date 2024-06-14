# QBTarr - Servarr docker, with some jelly

The idea is to generate a `compose.yml` file for `docker compose` with the services (sonarr, radarr, jellyfin, ...) configured to be accessed through a proxy (Traefik) via a subpath URL.

## Requirements

- docker
- cmake
- ccmake (optionnal)

## How to use

Clone this git and move in the directory
```
git clone https://github.com/Ezka77/qbtarr.git
cd qbtarr
```

### Configure your install

To get bazarr, sonarr, radarr, prowlarr, lidarr, qbittorrent, jellyfin and jellyseerr:
```
cmake --preset default
```

By default it will install this project in `/var/lib`; to install else where use `--install-prefix`
```
cmake --preset default --install-prefix /tmp/whatever
```

You can configure your media directory path with `DDATA_DIRECTORY_PATH`, for exemple to put all your downloads in `/srv/media` use the command like so:
```
cmake --preset default -DDATA_DIRECTORY_PATH=/srv/media
```
The installation will create `downloads`, `movies`, `music` and `series` directories. 

#### Advanced

Use `ccmake` to configure everything. You can use Transmission instead of QBittorrent, and remove undesired services.

### Install

```
cmake --install build
```

## Servarr'n'Jelly Configuration

Next start the services from the install directory:
```
cd /var/lib/qbtarr
docker compose up -d
```

Eventually you should have access to the configured services to theses adresses:

| service | localhost uri |
| --- | --- |
| prowlarr    | http://localhost/prowlarr |
| sonarr      | http://localhost/sonarr |
| radarr      | http://localhost/radarr |
| lidarr      | http://localhost/lidarr |
| bazarr      | http://localhost/bazarr |
| qbittorrent | http://localhost/qb |
| jellyfin    | http://localhost/jellyfin |
| jellyseerr  | http://localhost:5055 |

Next is to configure your services as required (see https://wiki.servarr.com/)


### Configuration tips

Start by configuring Prowlarr and QBittorrent; next configure sonarr, radarr and lidarr, add them to prowlarr and find some indexers.
Each container can access to the other ones by using docker containers names:

| service | in docker uri |
| --- | --- |
| prowlarr    | `http://prowlarr:9696/prowlarr` |
| sonarr      | `http://sonarr:8989/sonarr` |
| radarr      | `http://radarr:7878/radarr` |
| lidarr      | `http://lidarr:8686/lidarr` |
| qbittorrent | `http://qbittorrent:8080` |
| jellyfin    | `http://jellyfin:8096/jellyfin` |

For exemple the sonarr uri from prowlarr is `http://sonarr:8989/sonarr` and sonarr can access to prowlarr by using the uri `http://prowlarr:9696/prowlarr`.


Note that QBittorrent uri for servarr is: `http://qbittorrent:8080` and you need to set a user:password. 
To do so, for your first connection you can look the qbittorrent logs, it creates some random credential if none are set.
```
docker compose logs qbittorrent
```

## Container updates

To download new versions of the images, from the installation directory you can run this command:
```
docker compose up -d --pull always
```
NB: A monthly/weekly cron job should be enough

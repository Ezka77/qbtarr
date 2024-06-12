# QBTarr - Servarr docker, with some jelly

The idea is to generate a `compose.yml` file for `docker compose` with the services (sonarr, radarr, jellyfin, ...) configured to be accessed through a proxy (Traefik) via a subpath URL.

## Requirements

- docker
- cmake
- ccmake

## How to use

Clone this git and move in the directory
```
git clone https://github.com/Ezka77/qbtarr.git
cd qbtarr
```

### The eazy way

Create the `build` directory and generate the base configuration and directories layout:
```
cmake -B build
```

Personnalize your services by enabling them with ccmake for exemple (or any cmake-gui tool):
```
ccmake build
```

I would advise to start with Traefik, Prowlarr and QBittorrent. Make everything work together and then start adding the other services.
You can add as much servarr as wanted by running `ccmake` and switch them to `ON` and repeat the next install command.
When a service switch is `OFF` then the service entry is removed from the main `compose.yml`, the service directory is NOT deleted.

###  The lazy way -- if not using the eazy way above

Assume you don't understand anything above (or for any other reason) and you want to start the next step asap
```
cmake --preset default
```

## The DATA_DIRECTORY_PATH

Set this variable to point where you want to store your medias. Again use `ccmake` for that:

```
ccmake build
```

## Installation

To change the default install path, use `ccmake build`, edit the `CMAKE_INSTALL_PREFIX` value, hit `c` for `configure` to save and next `g` to propagate your changes to the install scripts.
By default the generated files are installed in `/var/lib/qbtarr`. 
```
cd build
make install
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


### First step

You should configure Prowlarr with some indexers, next add sonarr, radarr and lidarr to prowlarr.
Each container can access to the other ones by using dns names:

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

To download new versions of the images, from the installation directory you can call this command:
```
docker compose up -d --pull always
```

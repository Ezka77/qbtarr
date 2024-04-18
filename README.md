# QBTarr - yet another servarr docker

Some minimum services from servarr in a docker compose wrapper file

## How to use

`docker compose up -d` next you should have access to the servarr services and qbittorrent at:

- http://localhost/prowlarr
- http://localhost/sonarr
- http://localhost/radarr
- http://localhost/qbt/

next step is to configure your services as required: it's a bare minimum docker-compose.yml file with some very basic configurations only provided to enable the access to all services.

For more help see https://wiki.servarr.com/

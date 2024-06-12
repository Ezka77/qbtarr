cmake_minimum_required(VERSION 3.27)

# no LANGUAGES ... I use cmake to generate configuration
project(qbtarr VERSION 0.0.1 LANGUAGES)

# For now: if install prefix is default-ed use /
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "/" CACHE PATH "..." FORCE)
endif()

# Add source cmake dir to module path
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

set(INSTALL_VAR var/lib)
set(DATA_DIRECTORY_PATH ./data CACHE PATH "path to shared directory")

# containers env -- configured from ccmake
set(PUID 1000 CACHE STRING "uid")
set(PGID 1000 CACHE STRING "gid")
set(UMASK 002 CACHE STRING "umask")
set(TZ Europe/Paris CACHE STRING "Time Zone")

set(GEN_DIR generated)

include(AddService)
include(AddDcfCommand)

# configure
set_service_workdir(${GEN_DIR}/${CMAKE_PROJECT_NAME})

# add default data directories (for tests) -- target ?
add_data_dir()

# services
message("Enabled services:")
add_service(prowlarr)
add_service(lidarr)
add_service(radarr)
add_service(sonarr)
add_service(qbittorrent)
add_service(transmission DIRECTORY watch)
add_service(mpd DIRECTORY config/playlists)
add_service(mympd DIRECTORY data cache)
add_service(nginx)
add_service(traefik)
add_service(jellyfin)
add_service(jellyseerr DIRECTORY config)
add_service(bazarr DIRECTORY config)

# and in the end create the compose file -- TODO: add a target instead ?
add_compose()

# ugly shortcut scripts
add_dcf()




cmake_minimum_required(VERSION 3.27)

# no LANGUAGES ... I use cmake to generate configuration
project(qbtarr VERSION 0.0.1 LANGUAGES)

# For now: if install prefix is default-ed use /
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "/" CACHE PATH "..." FORCE)
endif()

# Add cmake dir to module path
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

set(INSTALL_VAR var/lib)
set(DATA_DIRECTORY_PATH ./data CACHE PATH "path to shared directory")

# containers env 
set(PUID 1000 CACHE STRING "uid")
set(PGID 1000 CACHE STRING "gid")
set(UMASK 002 CACHE STRING "umask")
set(TZ Europe/Paris CACHE STRING "Time Zone")

set(GEN_DIR generated)

configure_file(scripts/docker_compose_f.in scripts/dcf @ONLY)
file(CHMOD ${CMAKE_BINARY_DIR}/scripts/dcf 
  PERMISSIONS 
  OWNER_READ OWNER_WRITE OWNER_EXECUTE 
  GROUP_READ GROUP_EXECUTE 
  WORLD_READ WORLD_EXECUTE
)
file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
file(CREATE_LINK ${CMAKE_BINARY_DIR}/scripts/dcf ${CMAKE_BINARY_DIR}/bin/start SYMBOLIC)
file(CREATE_LINK ${CMAKE_BINARY_DIR}/scripts/dcf ${CMAKE_BINARY_DIR}/bin/stop SYMBOLIC)
file(CREATE_LINK ${CMAKE_BINARY_DIR}/scripts/dcf ${CMAKE_BINARY_DIR}/bin/logs SYMBOLIC)

include(AddService)
# configure
set_service_workdir(${GEN_DIR}/${CMAKE_PROJECT_NAME})

# add default data directories
add_data()

# our services
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
add_service(jellyfin DIRECTORY config)
add_service(jellyseerr DIRECTORY config)
add_service(bazarr DIRECTORY config)

# and in the end create the compose file
add_compose_and_env()

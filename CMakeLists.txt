cmake_minimum_required(VERSION 3.27)

# no LANGUAGES ... I use cmake to generate configuration
project(qbtarr VERSION 0.0.1 LANGUAGES)

# For now: if install prefix is default-ed use /
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "/" CACHE PATH "..." FORCE)
endif()

set(INSTALL_INIT etc/init.d)
set(INSTALL_VAR var/lib)

set(SVCNAME ${CMAKE_PROJECT_NAME})

set(DATA_DIRECTORY_PATH ./data CACHE PATH "path to shared directory")

# containers env 
set(PUID 1000 CACHE STRING "uid")
set(PGID 1000 CACHE STRING "gid")
set(UMASK 002 CACHE STRING "umask")
set(TZ Europe/Paris CACHE STRING "Time Zone")

# Init scripts
option(OPT_OPENRC       "Add OpenRC init script"  OFF)
# servers
option(OPT_PROWLARR     "Add prowlarr server"     OFF)
option(OPT_LIDARR       "Add lidarr server"       OFF)
option(OPT_RADARR       "Add radarr server"       OFF)
option(OPT_SONARR       "Add sonarr server"       OFF)

option(OPT_QBITTORRENT  "Add qbittorrent client"  OFF)
option(OPT_TRANSMISSION "Add transmission client" OFF)

option(OPT_MPD          "Add MPD server"          OFF)
option(OPT_MYMPD        "Add myMPD server"        OFF)
option(OPT_TRAEFIK      "Traefik reverse proxy"   OFF)
option(OPT_NGINX        "NginX as reverse proxy"  OFF)

set(OPENRC_DIR  sbin)    # OpenRC-run directory (/sbin)
set(GEN_DIR rootfs)
set(DCS_DIR  ${GEN_DIR}/dcs)
set(WORK_DIR ${GEN_DIR}/${SVCNAME})

set(SRV_BIN_DIR ${CMAKE_BINARY_DIR}/${WORK_DIR}/services)

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

# configure files
if (${OPT_OPENRC})
  configure_file(openrc/dcs.in ${DCS_DIR}/dcs @ONLY)
  # create a dcs sub-service
  file(CREATE_LINK  dcs  ${CMAKE_BINARY_DIR}/${DCS_DIR}/dcs.${SVCNAME} SYMBOLIC)
endif()

# create includes to configure our docker-compose file and add optional services
set(INCLUDE_LIST "# enabled services\ninclude:")

# create shared directories
file(MAKE_DIRECTORY 
  ${CMAKE_BINARY_DIR}/${WORK_DIR}/data/downloads
  ${CMAKE_BINARY_DIR}/${WORK_DIR}/data/music
  ${CMAKE_BINARY_DIR}/${WORK_DIR}/data/series
  ${CMAKE_BINARY_DIR}/${WORK_DIR}/data/movies
)

function(add_service name)
  string(TOUPPER OPT_${name} OPTNAME)
  if (NOT DEFINED ${OPTNAME})
    message(WARNING "${OPTNAME} option is not defined!")
    return()
  elseif (NOT ${${OPTNAME}})
    return()
  endif()
  # add the service compose yml in our list
  list(APPEND INCLUDE_LIST "\
  - path: services/${name}/${name}.yml\n\
    project_directory: .")
  set(INCLUDE_LIST ${INCLUDE_LIST} PARENT_SCOPE)
  # copy service directory
  file(COPY services/${name} DESTINATION ${WORK_DIR}/services)
  # from function arguments parse everything
  set(options)
  set(oneValueArgs)
  set(multiValueArgs DIRECTORY)
  cmake_parse_arguments(ADD_SERVICES "${options}" "${oneValueArgs}"
    "${multiValueArgs}" ${ARGN})
  # create any given sub-directory
  if(DEFINED ADD_SERVICES_DIRECTORY)
    list(TRANSFORM ADD_SERVICES_DIRECTORY PREPEND ${SRV_BIN_DIR}/${name}/)
    file(MAKE_DIRECTORY ${ADD_SERVICES_DIRECTORY})
  endif()
  message(STATUS ${name})
endfunction()

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

## Create the compose.yml with the list of included files
set(INCLUDE_SERVICES "---")
list(LENGTH INCLUDE_LIST NB_INCLUDES)
if ( ${NB_INCLUDES} GREATER 1)
  # join strings to create a YAML list
  list(JOIN INCLUDE_LIST "\n" INCLUDE_SERVICES)
else()
  message(WARNING "No services enabled! Use `ccmake` or `cmake --preset <name>`")
endif()

configure_file(compose.yml.in ${WORK_DIR}/compose.yml @ONLY)
configure_file(srv.env.in     ${WORK_DIR}/srv.env @ONLY)

# Quick & Dirty custom targets
# commands to start/stop containers with a target - shortcut to test generated files
add_custom_target(logs
  COMMAND docker compose logs
  WORKING_DIRECTORY ${WORK_DIR}
  COMMENT "print containers logs"
  VERBATIM
)

add_custom_target(start
  COMMAND docker compose up -d
  WORKING_DIRECTORY ${WORK_DIR}
  COMMENT "create, start and fork containers"
  VERBATIM
)

# cmake --build build/ --target start
add_custom_target(stop
  COMMAND docker compose down
  WORKING_DIRECTORY ${WORK_DIR}
  COMMENT "stop containers"
  VERBATIM
)

# Install the generated files in var/lib/dcs
install(DIRECTORY 
  ${CMAKE_BINARY_DIR}/${WORK_DIR}
  DESTINATION ${INSTALL_VAR}
  USE_SOURCE_PERMISSIONS
  COMPONENT ${CMAKE_PROJECT_NAME}
)
# TODO: need to change UID:GID of ${WORK_DIR_N}/* directories

# Theses ones can stay as root:root
install(FILES
  ${CMAKE_BINARY_DIR}/${DCS_DIR}/dcs
  ${CMAKE_BINARY_DIR}/${DCS_DIR}/dcs.${SVCNAME}
  DESTINATION ${INSTALL_INIT}
  CONFIGURATIONS WithOpenRC
)

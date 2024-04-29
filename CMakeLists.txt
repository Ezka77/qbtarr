cmake_minimum_required(VERSION 3.27)

project(qbtarr VERSION 0.0.1)

# For now: if install prefix is default-ed use /
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "/" CACHE PATH "..." FORCE)
endif()

set(INSTALL_INIT etc/init.d)
set(INSTALL_VAR var/lib/dcs)

set(SVCNAME ${CMAKE_PROJECT_NAME})

# containers env 
set(PUID 1000)
set(PGID 1000)
set(UMASK 002)
set(TZ Europe/Paris)

# Init scripts
option(OPT_OPENRC       "Add OpenRC init script"  OFF)
# servers
option(OPT_PROWLARR     "Add prowlarr server"     ON )
option(OPT_LIDARR       "Add lidarr server"       OFF)
option(OPT_RADARR       "Add radarr server"       OFF)
option(OPT_SONARR       "Add sonarr server"       OFF)

option(OPT_QBITORRENT   "Add qbittorrent client"  OFF)
option(OPT_TRANSMISSION "Add transmission client" OFF)

option(OPT_MYMPD        "Add myMPD server"            OFF)
option(OPT_NGINX        "Add NginX as reverse proxy"  OFF)

set(OPENRC_DIR  sbin)    # OpenRC-run directory (/sbin)
set(GEN_DIR generate)
set(DCS_DIR  ${GEN_DIR}/dcs)
set(WORK_DIR ${GEN_DIR}/${SVCNAME})

# configure files
if (${OPT_OPENRC})
  configure_file(openrc/dcs.in ${DCS_DIR}/dcs @ONLY)
  # create a dcs sub-service
  file(CREATE_LINK  dcs  ${CMAKE_BINARY_DIR}/${DCS_DIR}/dcs.${SVCNAME} SYMBOLIC)
endif()

# create includes to configure our docker-compose file and add optional services
set(INCLUDE_LIST "# include of optional services\ninclude:")

# create shared directories
file(MAKE_DIRECTORY 
  ${CMAKE_BINARY_DIR}/${WORK_DIR}/data/downloads
  ${CMAKE_BINARY_DIR}/${WORK_DIR}/data/music
  ${CMAKE_BINARY_DIR}/${WORK_DIR}/data/series
  ${CMAKE_BINARY_DIR}/${WORK_DIR}/data/movies
)

function(add_service option name)
  if (${option})
    list(APPEND INCLUDE_LIST "\
  - path: services/${name}/${name}.yml\n\
    project_directory: .")
    set(INCLUDE_LIST ${INCLUDE_LIST} PARENT_SCOPE)
    file(COPY services/${name} DESTINATION ${WORK_DIR}/services)
  endif()
endfunction()

add_service(${OPT_PROWLARR}   prowlarr)
add_service(${OPT_LIDARR}     lidarr)
add_service(${OPT_RADARR}     radarr)
add_service(${OPT_SONARR}     sonarr)
add_service(${OPT_QBITORRENT}   qbittorrent)
add_service(${OPT_TRANSMISSION} transmission)
if (${OPT_TRANSMISSION})
  file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/${WORK_DIR}/services/transmission/watch)
endif()
add_service(${OPT_MYMPD}      mympd)
if (${OPT_MYMPD})
  file(MAKE_DIRECTORY 
    ${CMAKE_BINARY_DIR}/${WORK_DIR}/services/mympd/data
    ${CMAKE_BINARY_DIR}/${WORK_DIR}/services/mympd/cache
  )
endif()
add_service(${OPT_NGINX} nginx)

## Create the compose.yml with the list of included files
set(INCLUDE_SERVICES "---")
list(LENGTH INCLUDE_LIST NB_INCLUDES)
if ( ${NB_INCLUDES} GREATER 1)
  # join strings to create a YAML list
  list(JOIN INCLUDE_LIST "\n" INCLUDE_SERVICES)
endif()

configure_file(compose.yml.in ${WORK_DIR}/compose.yml @ONLY)
configure_file(srv.env.in     ${WORK_DIR}/srv.env @ONLY)


# Quick & Dirty custom targets
# commands to start/stop containers with a target - shortcut to test our install
add_custom_target(start
  COMMAND docker compose up
  WORKING_DIRECTORY ${WORK_DIR}
  COMMENT "start containers"
  VERBATIM
)

add_custom_target(startd
  COMMAND docker compose up -d
  WORKING_DIRECTORY ${WORK_DIR}
  COMMENT "start containers"
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

cmake_minimum_required(VERSION 3.27)

project(qbtarr VERSION 0.0.1)

# For now: if install prefix is default-ed use / as we build our own rootfs
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "/" CACHE PATH "..." FORCE)
endif()

set(INSTALL_INIT etc/init.d)
set(INSTALL_VAR var/lib/dcs)

set(ROOTFS generated)
set(SVCNAME ${CMAKE_PROJECT_NAME})

set(OPENRC_DIR  sbin)         # "OpenRC-run directory (/sbin)"

# containers env 
set(PUID 1000)
set(PGID 1000)
set(UMASK 002)
set(TZ Europe/Paris)

# Init scripts
option(OPENRC "Add OpenRC init script" OFF)

# *arr servers
#option(PROWLARR "Add the *arr server" OFF)
#option(LIDARR   "Add the *arr server" OFF)
#option(RADARR   "Add the *arr server" OFF)
#option(SONARR   "Add the *arr server" OFF)

option(QBT   "Add the qbittorrent client" OFF)

# multimedia servers
option(MYMPD   "Add myMPD server" OFF)

# frontend
option(NGINX   "Add NginX as reverse proxy" OFF)

# normalize and set definitive paths
cmake_path(SET DSC_DIR NORMALIZE ${ROOTFS}/dcs)
cmake_path(SET WORK_DIR NORMALIZE ${ROOTFS}/${SVCNAME})

# TODO: split the CMake file and add_directories ? or add a cmake module with a function like
# add_services(mympd) which will:
# - add the subdirectory where we define a list of directories to create in a variable
# - create theses runtime directorie eg: services/mympd/[cache, config]
# - add to nginx (if enabled) the service configuration for it
# - add an include for the docker compose yml

# configure files
if (${OPENRC})
  configure_file(openrc/dcs.in ${DSC_DIR}/dcs @ONLY)
  # create a dcs sub-service
  file(CREATE_LINK  dcs  ${CMAKE_BINARY_DIR}/${DSC_DIR}/dcs.${SVCNAME} SYMBOLIC)
endif()

# create includes to configure our docker-compose file and add optional services
set(DC_INCLUDES "# include of optional services\ninclude:")
if (${MYMPD})
  list(APPEND DC_INCLUDES "mympd.yml")
endif()
if (${NGINX})
  # add docker service
  list(APPEND DC_INCLUDES "nginx.yml")
endif()
if (${QBT})
  # add docker service
  list(APPEND DC_INCLUDES "qbt.yml")
endif()

set(DC_INC "---")
list(LENGTH DC_INCLUDES NB_INCLUDES)
if ( ${NB_INCLUDES} GREATER 1)
  # join strings to create a YAML list
  list(JOIN DC_INCLUDES "\n  - " DC_INC)
endif()

configure_file(compose.yml.in ${WORK_DIR}/compose.yml @ONLY)
configure_file(hotio.env.in ${WORK_DIR}/hotio.env @ONLY)

# add directory tree - relative to source directory
file(MAKE_DIRECTORY 
  ${CMAKE_BINARY_DIR}/${WORK_DIR}/data/downloads
  ${CMAKE_BINARY_DIR}/${WORK_DIR}/data/music
  ${CMAKE_BINARY_DIR}/${WORK_DIR}/data/series
  ${CMAKE_BINARY_DIR}/${WORK_DIR}/data/movies
)
file(COPY config DESTINATION ${WORK_DIR})

if (${QBT})
  file(COPY services/qbittorrent/config DESTINATION ${WORK_DIR}/services/qbittorrent)
  file(COPY_FILE ./services/qbittorrent/qbt.yml ${CMAKE_BINARY_DIR}/${WORK_DIR}/qbt.yml ONLY_IF_DIFFERENT)
endif()

if (${MYMPD})
  file(MAKE_DIRECTORY 
    ${CMAKE_BINARY_DIR}/${WORK_DIR}/services/mympd/data
    ${CMAKE_BINARY_DIR}/${WORK_DIR}/services/mympd/cache
  )
  file(COPY_FILE services/mympd/mympd.yml ${CMAKE_BINARY_DIR}/${WORK_DIR}/mympd.yml ONLY_IF_DIFFERENT)
endif()

if (${NGINX})
  file(COPY services/nginx/qbtarr.d DESTINATION ${WORK_DIR}/services/nginx)
  file(COPY_FILE 
    services/nginx/nginx.yml 
    ${CMAKE_BINARY_DIR}/${WORK_DIR}/nginx.yml 
    ONLY_IF_DIFFERENT
  )
  file(COPY_FILE 
    services/nginx/nginx.conf 
    ${CMAKE_BINARY_DIR}/${WORK_DIR}/services/nginx/nginx.conf 
    ONLY_IF_DIFFERENT
  )
endif()

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
  ${CMAKE_BINARY_DIR}/${DSC_DIR}/dcs
  ${CMAKE_BINARY_DIR}/${DSC_DIR}/dcs.${SVCNAME}
  DESTINATION ${INSTALL_INIT}
  CONFIGURATIONS WithOpenRC
)

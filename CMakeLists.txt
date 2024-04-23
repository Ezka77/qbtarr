cmake_minimum_required(VERSION 3.27)

project(qbtarr VERSION 0.0.1)

# initialize build directory
# cmake -B build/

# For now: if install prefix is default-ed use / as we build our own rootfs
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "/" CACHE PATH "..." FORCE)
endif()

set(ROOTFS rootfs)
set(SVCNAME ${CMAKE_PROJECT_NAME})

set(OPENRC_DIR  sbin)         # "OpenRC-run directory (/sbin)"
set(INIT_DIR    etc/init.d)   # "OpenRC init.d directory (/etc/init.d)"
set(VAR_DIR     var/lib/dcs)  # "DCS workind directory (/var/lib/dcs)"

# containers env 
set(PUID 1000)
set(PGID 1000)
set(UMASK 002)
set(TZ Europe/Paris)

option(OPENRC "Add OpenRC init script" ON)

# normalize paths and set definitive paths
cmake_path(SET DCS_INI_N NORMALIZE ${ROOTFS}/${INIT_DIR})
cmake_path(SET DCS_DIR_N NORMALIZE ${ROOTFS}/${VAR_DIR}/${SVCNAME})

# configure files
if (${OPENRC})
  configure_file(openrc/dcs.in ${DCS_INI_N}/dcs @ONLY)
  # create a dcs sub-service
  file(CREATE_LINK  dcs  ${CMAKE_BINARY_DIR}/${DCS_INI_N}/dcs.${SVCNAME} SYMBOLIC)
endif()
configure_file(docker-compose.yml ${DCS_DIR_N}/docker-compose.yml @ONLY)
configure_file(hotio.env ${DCS_DIR_N}/hotio.env @ONLY)

# add directory tree - this one is relative to cmake current dir
file(MAKE_DIRECTORY 
  ${CMAKE_BINARY_DIR}/${DCS_DIR_N}/data/downloads
  ${CMAKE_BINARY_DIR}/${DCS_DIR_N}/data/music
  ${CMAKE_BINARY_DIR}/${DCS_DIR_N}/data/series
  ${CMAKE_BINARY_DIR}/${DCS_DIR_N}/data/movies
)
file(COPY config DESTINATION ${DCS_DIR_N})

# Quick & Dirty custom targets
# commands to start/stop containers with a target - shortcut to test our install
# cmake --build build/ --target start
add_custom_target(start
  COMMAND docker compose up -d
  WORKING_DIRECTORY ${DCS_DIR_N}
  COMMENT "start containers"
  VERBATIM
)

# cmake --build build/ --target start
add_custom_target(stop
  COMMAND docker compose down
  WORKING_DIRECTORY ${DCS_DIR_N}
  COMMENT "stop containers"
  VERBATIM
)

# Install
install(DIRECTORY 
  ${CMAKE_BINARY_DIR}/${ROOTFS}/var/lib/dcs
  DESTINATION var/lib
  USE_SOURCE_PERMISSIONS
  COMPONENT ${SVCNAME}
)
# TODO: need to change UID:GID of ${DCS_DIR_N}/* directories

# Theses ones can stay as root:root
install(FILES
  ${CMAKE_BINARY_DIR}/${DCS_INI_N}/dcs
  ${CMAKE_BINARY_DIR}/${DCS_INI_N}/dcs.${SVCNAME}
  DESTINATION etc/init.d/
  CONFIGURATION WithOpenRC
)

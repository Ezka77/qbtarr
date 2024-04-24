cmake_minimum_required(VERSION 3.27)

project(qbtarr VERSION 0.0.1)

# For now: if install prefix is default-ed use / as we build our own rootfs
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "/" CACHE PATH "..." FORCE)
endif()

set(ROOTFS generated)
set(SVCNAME ${CMAKE_PROJECT_NAME})

set(OPENRC_DIR  sbin)         # "OpenRC-run directory (/sbin)"

# containers env 
set(PUID 1000)
set(PGID 1000)
set(UMASK 002)
set(TZ Europe/Paris)

option(OPENRC "Add OpenRC init script" OFF)

# normalize paths and set definitive paths
cmake_path(SET DSC_DIR NORMALIZE ${ROOTFS}/dcs)
cmake_path(SET WORK_DIR NORMALIZE ${ROOTFS}/${SVCNAME})

# configure files
if (${OPENRC})
  configure_file(openrc/dcs.in ${DSC_DIR}/dcs @ONLY)
  # create a dcs sub-service
  file(CREATE_LINK  dcs  ${CMAKE_BINARY_DIR}/${DSC_DIR}/dcs.${SVCNAME} SYMBOLIC)
endif()
configure_file(docker-compose.yml ${WORK_DIR}/docker-compose.yml @ONLY)
configure_file(hotio.env ${WORK_DIR}/hotio.env @ONLY)

# add directory tree - relative to source directory
file(MAKE_DIRECTORY 
  ${CMAKE_BINARY_DIR}/${WORK_DIR}/data/downloads
  ${CMAKE_BINARY_DIR}/${WORK_DIR}/data/music
  ${CMAKE_BINARY_DIR}/${WORK_DIR}/data/series
  ${CMAKE_BINARY_DIR}/${WORK_DIR}/data/movies
  ${CMAKE_BINARY_DIR}/${WORK_DIR}/mympd/data
  ${CMAKE_BINARY_DIR}/${WORK_DIR}/mympd/cachedir
)
file(COPY config DESTINATION ${WORK_DIR})

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

# Install
install(DIRECTORY 
  ${CMAKE_BINARY_DIR}/${WORK_DIR}
  DESTINATION var/lib/dcs
  USE_SOURCE_PERMISSIONS
  COMPONENT ${CMAKE_PROJECT_NAME}
)
# TODO: need to change UID:GID of ${WORK_DIR_N}/* directories

# Theses ones can stay as root:root
install(FILES
  ${CMAKE_BINARY_DIR}/${DSC_DIR}/dcs
  ${CMAKE_BINARY_DIR}/${DSC_DIR}/dcs.${SVCNAME}
  DESTINATION etc/init.d/
  CONFIGURATIONS WithOpenRC
)

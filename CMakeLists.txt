cmake_minimum_required(VERSION 3.27)

project(qbtarr VERSION 0.0.1)

set(ROOTFS rootfs)
set(SVCNAME ${CMAKE_PROJECT_NAME})

set(OPENRC_DIR  /sbin)         # "OpenRC-run directory (/sbin)"
set(INIT_DIR    /etc/init.d)   # "OpenRC init.d directory (/etc/init.d)"
set(VAR_DIR     /var/lib/dcs)  # "DCS workind directory (/var/lib/dcs)"

# normalize paths and set definitive paths
cmake_path(SET DCS_INI_N NORMALIZE ${ROOTFS}/${INIT_DIR})
cmake_path(SET DCS_DIR_N NORMALIZE ${ROOTFS}/${VAR_DIR}/${SVCNAME})

# configure files with our paths
configure_file(openrc/dcs.in ${DCS_INI_N}/dcs @ONLY)
configure_file(docker-compose.yml ${DCS_DIR_N}/docker-compose.yml @ONLY)
configure_file(hotio.env ${DCS_DIR_N}/hotio.env @ONLY)

# add directory tree - this one is relative to cmake current dir by default
file(MAKE_DIRECTORY 
  ${CMAKE_BINARY_DIR}/${DCS_DIR_N}/downloads
  ${CMAKE_BINARY_DIR}/${DCS_DIR_N}/data/prowlarr
  ${CMAKE_BINARY_DIR}/${DCS_DIR_N}/data/sonarr
  ${CMAKE_BINARY_DIR}/${DCS_DIR_N}/data/radarr
)
file(COPY config DESTINATION ${DCS_DIR_N})

# create a dcs sub-service
file(CREATE_LINK  dcs ${DCS_INI_N}/dcs.${SVCNAME} SYMBOLIC)

# commands to start/stop containers
add_custom_target(start
  COMMAND docker compose up -d
  WORKING_DIRECTORY ${DCS_DIR_N}
  COMMENT "start containers"
  VERBATIM
)

add_custom_target(stop
  COMMAND docker compose down
  WORKING_DIRECTORY ${DCS_DIR_N}
  COMMENT "stop containers"
  VERBATIM
)

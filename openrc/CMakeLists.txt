
set(INSTALL_INIT etc/init.d)
set(OPENRC_DIR  sbin)    # OpenRC-run directory (/sbin)
set(DCS_DIR  ${GEN_DIR}/dcs)

# configure files
if (${OPT_OPENRC})
  configure_file(openrc/dcs.in ${DCS_DIR}/dcs @ONLY)
  # create a dcs sub-service
  file(CREATE_LINK  dcs  ${CMAKE_BINARY_DIR}/${DCS_DIR}/dcs.${CMAKE_PROJECT_NAME} SYMBOLIC)
endif()


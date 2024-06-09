
function(add_dcf)
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
endfunction()


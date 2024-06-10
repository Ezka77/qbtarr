# Utility module to add a service

# List of string shared by these next functions to create a list of services to add to the yaml compose file
set(INCLUDE_LIST "# enabled services\ninclude:")

# define the workdir: where the compose.yml is created
function(set_service_workdir path)
  set(WORK_DIR ${path} PARENT_SCOPE)
endfunction()

# create some data directories that can be use to test the services -- optional
function(add_data)
  if(DEFINED WORK_DIR)
    file(MAKE_DIRECTORY 
    ${CMAKE_BINARY_DIR}/${WORK_DIR}/data/downloads
    ${CMAKE_BINARY_DIR}/${WORK_DIR}/data/music
    ${CMAKE_BINARY_DIR}/${WORK_DIR}/data/series
    ${CMAKE_BINARY_DIR}/${WORK_DIR}/data/movies
    )
  else()
    message(FATAL_ERROR  "Can't create data directory: WORK_DIR not defined! use set_service_workdir() before.")
  endif()
endfunction()

# Add a service
# name: the name of the service in source directory
# DIRECTORY <...> : a list of directory to create
function(add_service name)
  string(TOUPPER OPT_${name} OPTNAME)
  option(${OPTNAME} "enable service ${name}" OFF)

  # if not enabled, return
  if (NOT ${${OPTNAME}})
    return()
  endif()

  # from function arguments parse everything
  set(options)
  set(oneValueArgs)
  set(multiValueArgs DIRECTORY)
  cmake_parse_arguments(ADD_SERVICES "${options}" "${oneValueArgs}"
    "${multiValueArgs}" ${ARGN})

  # add the service compose yml in our list
  list(APPEND INCLUDE_LIST "\
  - path: services/${name}/${name}.yml\n\
    project_directory: .")
  set(INCLUDE_LIST ${INCLUDE_LIST} PARENT_SCOPE)
  # copy service directory
  file(COPY services/${name} DESTINATION ${WORK_DIR}/services)
  # create any given sub-directory
  if(DEFINED ADD_SERVICES_DIRECTORY)
    set(SRV_BIN_DIR ${CMAKE_BINARY_DIR}/${WORK_DIR}/services)
    list(TRANSFORM ADD_SERVICES_DIRECTORY PREPEND ${SRV_BIN_DIR}/${name}/)
    file(MAKE_DIRECTORY ${ADD_SERVICES_DIRECTORY})
  endif()
  message(STATUS ${name})

  # on install do not overwrite if a service already exist ; installation = copy the service directory to the destination
  set(SERVICE_INSTALL_PATH ${CMAKE_INSTALL_PREFIX}/${INSTALL_VAR}/${CMAKE_PROJECT_NAME}/services)
  cmake_path(ABSOLUTE_PATH SERVICE_INSTALL_PATH NORMALIZE OUTPUT_VARIABLE SERVICE_INSTALL_PATH)
  install(CODE "
  if(NOT EXISTS ${SERVICE_INSTALL_PATH}/${name})
      file(INSTALL ${CMAKE_BINARY_DIR}/${WORK_DIR}/services/${name}
        DESTINATION ${SERVICE_INSTALL_PATH}
        USE_SOURCE_PERMISSIONS)
    else()
      message(STATUS  \"${name} not installed: this service already exist at destination.\")
    endif()"
  )
endfunction()

function(add_compose)
  ## Create the compose.yml with the list of included files
  set(YML_SERVICES "---")
  list(LENGTH INCLUDE_LIST NB_INCLUDES)
  if ( ${NB_INCLUDES} GREATER 1)
    # join strings to create a YAML list
    list(JOIN INCLUDE_LIST "\n" YML_SERVICES)
  else()
    message(WARNING "No services enabled! Use `ccmake` or `cmake --preset <name>`")
  endif()

  # generate the compose file
  configure_file(compose.yml.in ${WORK_DIR}/compose.yml @ONLY)
  configure_file(srv.env.in     ${WORK_DIR}/srv.env     @ONLY)

  # install the files in var/lib/qbtarr
  install(FILES 
    ${CMAKE_BINARY_DIR}/${WORK_DIR}/compose.yml
    ${CMAKE_BINARY_DIR}/${WORK_DIR}/srv.env
    DESTINATION ${INSTALL_VAR}/${CMAKE_PROJECT_NAME}
    )
endfunction()

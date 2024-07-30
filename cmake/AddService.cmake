# Utility module to add a service
option(FORCE_INSTALL "overwrite local install" OFF)

# List of string shared by these next functions to create a list of services to add to the yaml compose file
set(INCLUDE_LIST "# enabled services\ninclude:")

# define the workdir: where the compose.yml is created
function(set_service_workdir path)
  set(WORK_DIR ${path} PARENT_SCOPE)
endfunction()

function(add_data_dir)
  if(DEFINED WORK_DIR)
    cmake_path(IS_RELATIVE DATA_DIRECTORY_PATH IS_DATA_PATH_RELATIVE)
    if(${IS_DATA_PATH_RELATIVE})
      file(MAKE_DIRECTORY 
          ${CMAKE_BINARY_DIR}/${WORK_DIR}/${DATA_DIRECTORY_PATH}/downloads
          ${CMAKE_BINARY_DIR}/${WORK_DIR}/${DATA_DIRECTORY_PATH}/music
          ${CMAKE_BINARY_DIR}/${WORK_DIR}/${DATA_DIRECTORY_PATH}/series
          ${CMAKE_BINARY_DIR}/${WORK_DIR}/${DATA_DIRECTORY_PATH}/movies
      )

      # to display the full install path of the data directory
      set(QB_INSTALL_PATH ${CMAKE_INSTALL_PREFIX}/${DATA_DIRECTORY_PATH})
      cmake_path(NORMAL_PATH QB_INSTALL_PATH)
      message(STATUS "Data path is relative to install directory! Media directories will be created from the install path: ${QB_INSTALL_PATH}")
      install(DIRECTORY ${CMAKE_BINARY_DIR}/${WORK_DIR}/${DATA_DIRECTORY_PATH} 
              DESTINATION ${CMAKE_PROJECT_NAME})
    else()
      message(STATUS "Media directories will be created at ${DATA_DIRECTORY_PATH}, be sure your user have write permissions")
      install(DIRECTORY DESTINATION ${DATA_DIRECTORY_PATH}/downloads)
      install(DIRECTORY DESTINATION ${DATA_DIRECTORY_PATH}/music)
      install(DIRECTORY DESTINATION ${DATA_DIRECTORY_PATH}/series)
      install(DIRECTORY DESTINATION ${DATA_DIRECTORY_PATH}/movies)
    endif()

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
  set(SERVICE_INSTALL_PATH ${CMAKE_INSTALL_PREFIX}/${CMAKE_PROJECT_NAME}/services)
  cmake_path(ABSOLUTE_PATH SERVICE_INSTALL_PATH NORMALIZE OUTPUT_VARIABLE SERVICE_INSTALL_PATH)
  if (${FORCE_INSTALL})
    install(DIRECTORY ${CMAKE_BINARY_DIR}/${WORK_DIR}/services/${name}
            DESTINATION ${SERVICE_INSTALL_PATH}
            USE_SOURCE_PERMISSIONS)
  else()
    install(CODE "
      if(NOT EXISTS ${SERVICE_INSTALL_PATH}/${name})
          file(INSTALL ${CMAKE_BINARY_DIR}/${WORK_DIR}/services/${name}
            DESTINATION ${SERVICE_INSTALL_PATH}
            USE_SOURCE_PERMISSIONS)
        else()
          message(STATUS  \"${name} not installed: this service already exist at destination.\")
        endif()"
    )
  endif()
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
    DESTINATION ${CMAKE_PROJECT_NAME}
    )
endfunction()

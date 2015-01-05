get_filename_component(_self_dir "${CMAKE_CURRENT_LIST_FILE}" PATH)

set(LIBRARY_NAME_DEBUG_POSTFIX          "")
set(LIBRARY_NAME_RELEASE_POSTFIX        "")
set(LIBRARY_NAME_RELWITHDEBINFO_POSTFIX "")

set(OUTPUT_PATH_DEBUG           "Debug")
set(OUTPUT_PATH_RELEASE         "Release")
set(OUTPUT_PATH_RELWITHDEBINFO  "RelWithDebInfo")

if(CMAKE_BUILD_TOOL MATCHES MSBuild)
    set(LIBRARY_DIRS_HINT ${LIBRARY_OUTPUT_PATH})
else()
    set(LIBRARY_DIRS_HINT ${LIBRARY_OUTPUT_PATH}/${CMAKE_BUILD_TYPE})
endif()

ExternalProject_Add("${ZEROMQ_PROJECT}"
  DOWNLOAD_DIR "${download_dir}"
  GIT_REPOSITORY "${zeromq_git_repository}"
  GIT_TAG "${zeromq_git_tag}"
  INSTALL_COMMAND ""
  BUILD_IN_SOURCE 0
  CMAKE_ARGS
    -DWITHOUT_ASCIIDOC:BOOL=ON
    -DZMQ_BUILD_TESTS:BOOL=OFF
    -DBUILD_SHARED_LIBS:BOOL="${BUILD_SHARED_LIBS}"
    -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}"
    -DCMAKE_CXX_FLAGS_DEBUG=${CMAKE_CXX_FLAGS_DEBUG}
    -DCMAKE_CXX_FLAGS_RELEASE=${CMAKE_CXX_FLAGS_RELEASE}
    -DCMAKE_CXX_FLAGS_RELWITHDEBINFO=${CMAKE_CXX_FLAGS_RELWITHDEBINFO}
    -DLIBRARY_OUTPUT_PATH:PATH=${LIBRARY_DIRS_HINT}
    -DEXECUTABLE_OUTPUT_PATH:PATH=${EXECUTABLE_OUTPUT_PATH}
)

set_target_properties("${ZEROMQ_PROJECT}" PROPERTIES FOLDER "External Libraries" )

#
# Specify include directory
#
ExternalProject_Get_Property("${ZEROMQ_PROJECT}" SOURCE_DIR)
set(zeromq_include_dir ${SOURCE_DIR}/include CACHE STRING "Include directory for ${zeromq_library}.")
set(ZEROMQ_INCLUDE_DIR ${zeromq_include_dir} CACHE STRING "Include directories for ${zeromq_library}.")
set(ZEROMQ_INCLUDES    ${zeromq_include_dir} CACHE STRING "Include directories for ${zeromq_library}, including prerequisite libraries.")

#
# Specify the library
#
ExternalProject_Get_Property("${ZEROMQ_PROJECT}" BINARY_DIR)
set(ZEROMQ_LIBRARY_PATH_DEBUG          "${CMAKE_BINARY_DIR}/${LIB_OUTPUT_DIRECTORY}/${OUTPUT_PATH_DEBUG}")
set(ZEROMQ_LIBRARY_PATH_RELEASE        "${CMAKE_BINARY_DIR}/${LIB_OUTPUT_DIRECTORY}/${OUTPUT_PATH_RELEASE}")
set(ZEROMQ_LIBRARY_PATH_RELWITHDEBINFO "${CMAKE_BINARY_DIR}/${LIB_OUTPUT_DIRECTORY}/${OUTPUT_PATH_RELWITHDEBINFO}")
set(ZEROMQ_LIBRARY_DEBUG               "${CMAKE_FIND_LIBRARY_PREFIXES}${ZEROMQ_PROJECT}${LIBRARY_NAME_DEBUG_POSTFIX}")
set(ZEROMQ_LIBRARY_RELEASE             "${CMAKE_FIND_LIBRARY_PREFIXES}${ZEROMQ_PROJECT}${LIBRARY_NAME_RELEASE_POSTFIX}")
set(ZEROMQ_LIBRARY_RELWITHDEBINFO      "${CMAKE_FIND_LIBRARY_PREFIXES}${ZEROMQ_PROJECT}${LIBRARY_NAME_RELWITHDEBINFO_POSTFIX}")

# add the libraries to global scope and per configuration location to be linked
add_library(ZEROMQ_LIBRARIES STATIC IMPORTED GLOBAL)
set_target_properties(ZEROMQ_LIBRARIES PROPERTIES IMPORTED_LOCATION_DEBUG          "${ZEROMQ_LIBRARY_PATH_DEBUG}/${ZEROMQ_LIBRARY_DEBUG}${CMAKE_STATIC_LIBRARY_SUFFIX}")
set_target_properties(ZEROMQ_LIBRARIES PROPERTIES IMPORTED_LOCATION_RELEASE        "${ZEROMQ_LIBRARY_PATH_RELEASE}/${ZEROMQ_LIBRARY_RELEASE}${CMAKE_STATIC_LIBRARY_SUFFIX}")
set_target_properties(ZEROMQ_LIBRARIES PROPERTIES IMPORTED_LOCATION_RELWITHDEBINFO "${ZEROMQ_LIBRARY_PATH_RELWITHDEBINFO}/${ZEROMQ_LIBRARY_RELWITHDEBINFO}${CMAKE_STATIC_LIBRARY_SUFFIX}")

#add dependency so any project which includes library will automatically make ZEROMQ_PROJECT a dependency
add_dependencies(ZEROMQ_LIBRARIES "${ZEROMQ_PROJECT}")
                     
if (DEBUG_CMAKE)
    message("ZEROMQ_INCLUDE_DIR - ${ZEROMQ_INCLUDE_DIR}")
    message("ZEROMQ_INCLUDES    - ${ZEROMQ_INCLUDES}")
    message("ZEROMQ_LIBRARIES")
    message("  DEBUG            - ${ZEROMQ_LIBRARY_PATH_DEBUG}/${ZEROMQ_LIBRARY_DEBUG}${CMAKE_STATIC_LIBRARY_SUFFIX}")
    message("  RELEASE          - ${ZEROMQ_LIBRARY_PATH_RELEASE}/${ZEROMQ_LIBRARY_RELEASE}${CMAKE_STATIC_LIBRARY_SUFFIX}")
    message("  RELWITHDEBINFO   - ${ZEROMQ_LIBRARY_PATH_RELWITHDEBINFO}/${ZEROMQ_LIBRARY_RELWITHDEBINFO}${CMAKE_STATIC_LIBRARY_SUFFIX}")
endif()
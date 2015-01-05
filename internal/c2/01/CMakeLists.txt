#
# Copyright 2014 Qbase, LLC.
#
# CMake file for ClientStub executable
#

set(BINARY_BASENAME "c2-1")

message("\nConfiguring ${BINARY_BASENAME}...")

# The binary version number
set(BINARY_VERSION_MAJOR 1)
set(BINARY_VERSION_MINOR 0)
set(BINARY_VERSION_PATCH 0)
set(BINARY_VERSION "${BINARY_VERSION_MAJOR}.${BINARY_VERSION_MINOR}")
set(BINARY_VERSION_FULL "${BINARY_VERSION}.${BINARY_VERSION_PATCH}")

#
# Create lists of resource, header and source files
#
set(HEADER_FILES
   )
prefix_files(HEADER_FILES "include")
source_group("Header Files" FILES "${HEADER_FILES}")

set(SOURCE_FILES
    main.cpp
    SoundExTest.cpp
   )
prefix_files(SOURCE_FILES "src")

#
# Add directories to be searched for header files
#
set(INCLUDE_DIRECTORIES
    include
    ${GMOCK_INCLUDES}
   )

#
# Add libraries to link against
#
set(LINK_LIBRARIES
    GTEST_LIBRARIES
	GMOCK_MAIN_LIBRARIES
   )

#
# Create the library
#
memdb_test_binary(baseName           "${BINARY_BASENAME}"
                  version            "${BINARY_VERSION_FULL}"
                  headerFiles        "${HEADER_FILES}"
                  sourceFiles        "${SOURCE_FILES}"
                  resourceFiles      "${RESOURCE_FILES}"
                  includeDirectories "${INCLUDE_DIRECTORIES}"
                  linkLibraries      "${LINK_LIBRARIES}"
                 )

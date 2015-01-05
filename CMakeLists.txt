#
# Copyright 2014 Qbase, LLC.
#
# Root level file for the entire MemDB project directory.
#
CMAKE_MINIMUM_REQUIRED(VERSION 3.0.0)

project(CPP-TDD)

#
# Add the cmake directory into CMake's search path for modules
#
set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake" "${CMAKE_MODULE_PATH}")

#
# Limit the CMake configuration build types to Debug, Release and RelWithDebInfo
#
set(CMAKE_CONFIGURATION_TYPES "Debug" "Release" "RelWithDebInfo" CACHE TYPE INTERNAL FORCE)

#
# Include some useful utilities
#
include(AssertOutOfSourceBuild)
include(DetermineToolchainName)
include(DetermineArchitecture)
include(MemDBUtil)

#
# Set up the default library output path
#
set_property(GLOBAL PROPERTY USE_FOLDERS On)
set(EXECUTABLE_OUTPUT_PATH   "${CMAKE_BINARY_DIR}/${BIN_OUTPUT_DIRECTORY}")
set(LIBRARY_OUTPUT_PATH      "${CMAKE_BINARY_DIR}/${LIB_OUTPUT_DIRECTORY}")

fix_default_settings()

#create files for performing directory includes after all targets have been added
set(TARGET_INCLUDE_DIRECTORIES_FILE "${CMAKE_BINARY_DIR}/cmake-target_include_directories.txt" CACHE STRING "Target include lists")
FILE(WRITE "${TARGET_INCLUDE_DIRECTORIES_FILE}" "")
   
# add options for external targets 
option(BETA_BOOST "Build with beta version of boost" OFF)
   
add_subdirectory(external)

add_subdirectory(internal)

#perform the dereferencing of targets
#memdb_dereference_targets()

#
# Copyright 2014 Qbase, LLC.
#
# MemDB CMake functions for building libraries and binaries
#
include(CMakeParseArguments)
include(CheckCXXCompilerFlag)
include(PrefixFiles)

macro(memdb_append_flag flag)
    check_cxx_compiler_flag("${flag}" HAVE_FLAG_${flag})

    if(HAVE_FLAG_${flag})
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${flag}")
    endif()
endmacro()

macro(fix_default_settings)
    #
    # If it wasn't specified, set the default build type to RelWithDebInfo.
    #
    if(NOT ${CONFIG_NAME} STREQUAL $(ConfigurationName))
       SET(CMAKE_BUILD_TYPE $(ConfigurationName) CACHE STRING "Choose the type of build, options are: None Debug Release RelWithDebInfo MinSizeRel." FORCE)
    elseif(DEFINED CMAKE_BUILD_TYPE)
       SET(CMAKE_BUILD_TYPE ${CMAKE_BUILD_TYPE} CACHE STRING "Choose the type of build, options are: None Debug Release RelWithDebInfo MinSizeRel." FORCE)
    else()
       SET(CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "Choose the type of build, options are: None Debug Release RelWithDebInfo MinSizeRel." FORCE)
    endif()
    message(STATUS "Release type is ${CMAKE_BUILD_TYPE}")

    if (MSVC)
        set(MSVC_STATIC_RUNTIME ON CACHE BOOL "Link with MSVC static runtime.")
        
        #
        # For MSVC, CMake sets certain flags to defaults we want to override.
        #
        foreach(flag_var
                CMAKE_CXX_FLAGS CMAKE_CXX_FLAGS_DEBUG CMAKE_CXX_FLAGS_RELEASE CMAKE_CXX_FLAGS_RELWITHDEBINFO
               )
#            if(BUILD_SHARED_LIB)
#                set(RUNTIME_LIBRARY_TYPE "-md" CACHE STRING "Type of runtime MSVC runtime library that was linked.")
#            else()
#               message(STATUS "${flag_var} - ${${flag_var}}")
               string(REPLACE "/MD" "/MT" ${flag_var} "${${flag_var}}")
#               set(RUNTIME_LIBRARY_TYPE "-mt" CACHE STRING "Type of runtime MSVC runtime library that was linked.")
#               set(MSVC_STATIC_RUNTIME ON CACHE BOOL "Link with MSVC static runtime.")
#            endif()

# TODO            #Parallel make
#             memdb_append_flag("/MP")

            # Replaces /W3 with /W4 in defaults.
            string(REPLACE "/W1" "/W4" ${flag_var} "${${flag_var}}")
            string(REPLACE "/W2" "/W4" ${flag_var} "${${flag_var}}")
            string(REPLACE "/W3" "/W4" ${flag_var} "${${flag_var}}")
        endforeach()
     
        #set release and release with debug info flags
#        set(CMAKE_CXX_FLAGS_RELEASE "/MD /Ox /Ob2 /Ot /Oy /D NDEBUG")
#        set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "/MD /Zi /Ox /Ob2 /Ot /Oy")     
        
#        set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /GL")
#        set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE} /LTCG")
#        set(CMAKE_SHARED_LINKER_FLAGS_RELEASE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE} /LTCG")
#        set(CMAKE_MODULE_LINKER_FLAGS_RELEASE "${CMAKE_MODULE_LINKER_FLAGS_RELEASE} /LTCG")

        memdb_append_flag("-DWIN32_LEAN_AND_MEAN")

        #
        # Change the default number of file descriptors for sockets, the 
        # default for Windows is 64
        #
        memdb_append_flag("-DFD_SETSIZE=4096")
    else()
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
        memdb_append_flag("-Wall")
        memdb_append_flag("-pipe")
        memdb_append_flag(-fstack-protector -Wl,-z,relro -Wl,-z,now -Wformat-security)
        memdb_append_flag(-fvisibility=hidden)
        memdb_append_flag(-Wpointer-arith)
        memdb_append_flag(-Wformat-nonliteral)
        memdb_append_flag(-Winit-self)

        set(RUNTIME_LIBRARY_TYPE "" CACHE STRING "Type of runtime MSVC runtime library that was linked.")        
    endif()
endmacro()

#
# memdb_static_library( <baseName> <version>
#                       <headerFiles> <sourceFiles> <resourceFiles>
#                       <includeDirectories> <explicitLinkLang>)
#
# The <baseName> argument contains the base library name to use.  This will be wrapped
# in MemDB specific environment terms.
#
# The <version> argument contains the version number to use.
#
# The <headerFiles> argument contains a list of all the header files for
# this compilation unit.
#
# The <sourceFiles> argument contains a list of all the source files for
# this compilation unit.
#
# The <resourceFiles> argument, optional, contains a list of all the resource files for
# this compilation unit.
#
# The <includeDiretories> argument contains a list of all the header search
# paths for for this compilation unit.
#
# The <explicitLinkLang> argument is used for header only libraries.  This explicitly
# sets the linker language.
#
function(memdb_static_library)
    set(options)
    set(oneValueArgs baseName version explicitLinkLang)
    set(multiValueArgs headerFiles sourceFiles resourceFiles includeDirectories dependencies)
    cmake_parse_arguments(memdb_static_library "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    
    if (DEBUG_CMAKE)
        message("basename           - ${memdb_static_library_baseName}")
        message("version            - ${memdb_static_library_version}")
        message("headerFiles        - ${memdb_static_library_headerFiles}")
        message("sourceFiles        - ${memdb_static_library_sourceFiles}")
        message("resourceFiles      - ${memdb_static_library_resourceFiles}")
        message("includeDirectories - ${memdb_static_library_includeDirectories}")
        message("dependencies       - ${memdb_static_library_dependencies}")
        message("explicitLinkLang   - ${memdb_static_library_explicitLinkLang}")
    endif()

    #
    # Create the library names based on the configuration
    #
    #
    set(LIBRARY_NAME                "${memdb_static_library_baseName}")
    set(LIBRARY_NAME_DEBUG          "${LIBRARY_NAME}-${MEMDB_TOOLSET}-${MEMDB_ARCH}${RUNTIME_LIBRARY_TYPE}-d-${memdb_static_library_version}")
    set(LIBRARY_NAME_RELEASE        "${LIBRARY_NAME}-${MEMDB_TOOLSET}-${MEMDB_ARCH}${RUNTIME_LIBRARY_TYPE}-${memdb_static_library_version}")
    set(LIBRARY_NAME_RELWITHDEBINFO "${LIBRARY_NAME}-${MEMDB_TOOLSET}-${MEMDB_ARCH}${RUNTIME_LIBRARY_TYPE}-${memdb_shared_library_version}")
        
    set(${LIBRARY_NAME}_include_dir "${CMAKE_CURRENT_SOURCE_DIR}/include" CACHE STRING "Include directory for ${LIBRARY_NAME}.")
    
    #
    # Create the static library
    #
    message(STATUS "Library ${LIBRARY_NAME} will be built with ${CMAKE_CXX_FLAGS}")
    add_library("${LIBRARY_NAME}" STATIC "${memdb_static_library_headerFiles}" "${memdb_static_library_sourceFiles}" "${memdb_static_library_resourceFiles}")
    set_target_properties("${LIBRARY_NAME}" PROPERTIES FOLDER "Libraries"
                                                       OUTPUT_NAME_DEBUG          "${LIBRARY_NAME_DEBUG}"
                                                       OUTPUT_NAME_RELEASE        "${LIBRARY_NAME_RELEASE}"
                                                       OUTPUT_NAME_RELWITHDEBINFO "${LIBRARY_NAME_RELWITHDEBINFO}"
                                                       RUNTIME_OUTPUT_DIRECTORY   "${LIBRARY_OUTPUT_PATH}"
                                                       VERSION                    "${memdb_static_library_version}" )

    #
    # Add header files, library files, and dependecies which are queued and then processed after all targets
    #
    list(FIND memdb_static_library_includeDirectories "include" includeIndex)
    if (includeIndex GREATER -1)
        memdb_add_include_directories(target "${LIBRARY_NAME}" includeDirectories "include")    
        list(REMOVE_ITEM memdb_static_library_includeDirectories "include")
    endif()
    memdb_queue_include_directories("${LIBRARY_NAME}" "${memdb_static_library_includeDirectories}")
    memdb_add_dependencies(target "${LIBRARY_NAME}" dependencies "${memdb_static_library_dependencies}")                                                      
                                                       
    if( DEFINED memdb_static_library_explicitLinkLang )
        set_target_properties("${LIBRARY_NAME}" PROPERTIES LINKER_LANGUAGE CXX)
    endif()
endfunction(memdb_static_library)

#
# memdb_shared_library( <baseName> <version> <soversion>
#                       <headerFiles> <sourceFiles> <resourceFiles>
#                       <includeDirectories> <explicitLinkLang>)
#
# The <baseName> argument contains the base library name to use.  This will be wrapped
# in MemDB specific environment terms.
#
# The <version> argument contains the version number to use.
#
# The <soversion> argument contains the shared version number to use.
#
# The <headerFiles> argument contains a list of all the header files for
# this compilation unit.
#
# The <sourceFiles> argument contains a list of all the source files for
# this compilation unit.
#
# The <resourceFiles> argument, optional, contains a list of all the resource files for
# this compilation unit.
#
# The <includeDiretories> argument contains a list of all the header search
# paths for for this compilation unit.
#
# The <explicitLinkLang> argument is used for header only libraries.  This explicitly
# sets the linker language.
#
function(memdb_shared_library)
    set(options)
    set(oneValueArgs baseName version soversion explicitLinkLang)
    set(multiValueArgs headerFiles sourceFiles resourceFiles includeDirectories dependencies)
    cmake_parse_arguments(memdb_shared_library "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    
    if (DEFINED DEBUG_CMAKE)
        message("basename           - ${memdb_shared_library_baseName}")
        message("version            - ${memdb_shared_library_version}")
        message("soversion          - ${memdb_shared_library_soversion}")
        message("headerFiles        - ${memdb_shared_library_headerFiles}")
        message("sourceFiles        - ${memdb_shared_library_sourceFiles}")
        message("resourceFiles      - ${memdb_shared_library_resourceFiles}")
        message("includeDirectories - ${memdb_shared_library_includeDirectories}")
        message("dependencies       - ${memdb_binary_dependencies}")
        message("explicitLinkLang   - ${memdb_shared_library_explicitLinkLang}")
    endif()

    #
    # Create the library names based on the configuration
    #
    #
    set(LIBRARY_NAME                "${memdb_shared_library_baseName}")
    set(LIBRARY_NAME_DEBUG          "${LIBRARY_NAME}-${MEMDB_TOOLSET}-${MEMDB_ARCH}${RUNTIME_LIBRARY_TYPE}-d-${memdb_shared_library_version}")
    set(LIBRARY_NAME_RELEASE        "${LIBRARY_NAME}-${MEMDB_TOOLSET}-${MEMDB_ARCH}${RUNTIME_LIBRARY_TYPE}-${memdb_shared_library_version}")
    set(LIBRARY_NAME_RELWITHDEBINFO "${LIBRARY_NAME}-${MEMDB_TOOLSET}-${MEMDB_ARCH}${RUNTIME_LIBRARY_TYPE}-${memdb_shared_library_version}")
    
    set("${LIBRARY_NAME}_include_dir" "${CMAKE_CURRENT_SOURCE_DIR}/include" CACHE STRING "Include directory for ${LIBRARY_NAME}.")

    #
    # Create the shared library
    #
    message(STATUS "Library ${LIBRARY_NAME} will be built with ${CMAKE_CXX_FLAGS}")
    add_library("${LIBRARY_NAME}" SHARED "${memdb_shared_library_headerFiles}" "${memdb_shared_library_sourceFiles}" "${memdb_shared_library_resourceFiles}")
    set_property(TARGET "${LIBRARY_NAME}" PROPERTY FOLDER "Libraries")
    set_target_properties("${LIBRARY_NAME}" PROPERTIES DEFINE_SYMBOL              "COMPILING_DLL"
                                                       OUTPUT_NAME_DEBUG          "${LIBRARY_NAME_DEBUG}"
                                                       OUTPUT_NAME_RELEASE        "${LIBRARY_NAME_RELEASE}"
                                                       OUTPUT_NAME_RELWITHDEBINFO "${LIBRARY_NAME_RELWITHDEBINFO}"
                                                       RUNTIME_OUTPUT_DIRECTORY   "${EXECUTABLE_OUTPUT_PATH}"
                                                       SOVERSION                  "${memdb_shared_library_soversion}"
                                                       VERSION                    "${memdb_shared_library_version}" )
       
    
    #
    # Add header files, library files, and dependecies which are queued and then processed after all targets
    #
    list(FIND memdb_shared_library_includeDirectories "include" includeIndex)
    if (includeIndex GREATER -1)
        memdb_add_include_directories(target "${LIBRARY_NAME}" includeDirectories "include")    
        list(REMOVE_ITEM memdb_shared_library_includeDirectories "include")
    endif()
    memdb_queue_include_directories("${LIBRARY_NAME}" "${memdb_shared_library_includeDirectories}")
    memdb_add_dependencies(target "${LIBRARY_NAME}" dependencies "${memdb_shared_library_dependencies}") 

    if( DEFINED memdb_shared_library_explicitLinkLang )
        set_target_properties("${LIBRARY_NAME}" PROPERTIES LINKER_LANGUAGE CXX
                                                           IMPORT_SUFFIX "_imp.lib")
    endif()
endfunction(memdb_shared_library)

#
# MEMDB_BINARY(<baseName> <headerFiles> <sourceFiles> <resourceFiles> <includeDirectories> <linkDirectories>)
#
# The <baseName> argument contains base library name to use.  This will be wrapped
# in MemDB specific environment terms.
#
# The <version> argument contains the version number to use.
#
# The <headerFiles> argument contains a list of all the header files for
# this compilation unit.
#
# The <sourceFiles> argument contains a list of all the source files for
# this compilation unit.
#
# The <resourceFiles> argument, optional, contains a list of all the resource files for
# this compilation unit.
#
# The <includeDiretories> argument contains a list of all the header search
# paths for for this compilation unit.
#
# The <linkLibraries> argument, optional, contains a list of all the libraries
# to link with the binary.
#
function(memdb_binary)
    set(options)
    set(oneValueArgs baseName version)
    set(multiValueArgs headerFiles sourceFiles resourceFiles includeDirectories linkLibraries dependencies)
    cmake_parse_arguments(memdb_binary "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if (DEBUG_CMAKE)
        message("  basename           - ${memdb_binary_baseName}")
        message("  version            - ${memdb_binary_version}")
        message("  headerFiles        - ${memdb_binary_headerFiles}")
        message("  sourceFiles        - ${memdb_binary_sourceFiles}")
        message("  resourceFiles      - ${memdb_binary_resourceFiles}")
        message("  includeDirectories - ${memdb_binary_includeDirectories}")
        message("  linkLibraries      - ${memdb_binary_linkLibraries}")
        message("  dependencies       - ${memdb_binary_dependencies}")
    endif()
    
    #
    # Create the binary names based on the configuration
    #
    set(BINARY_NAME                "${memdb_binary_baseName}")
    set(BINARY_NAME_DEBUG          "${BINARY_NAME}-${MEMDB_TOOLSET}-${MEMDB_ARCH}${RUNTIME_LIBRARY_TYPE}-d-${memdb_binary_version}")
    set(BINARY_NAME_RELEASE        "${BINARY_NAME}-${MEMDB_TOOLSET}-${MEMDB_ARCH}${RUNTIME_LIBRARY_TYPE}-${memdb_binary_version}")
    set(BINARY_NAME_RELWITHDEBINFO "${BINARY_NAME}-${MEMDB_TOOLSET}-${MEMDB_ARCH}${RUNTIME_LIBRARY_TYPE}-${memdb_binary_version}")
    
    #
    # Create the binary
    #
    message(STATUS "Binary ${BINARY_NAME} will be built with ${CMAKE_CXX_FLAGS}")
    add_executable("${BINARY_NAME}" "${memdb_binary_headerFiles}" "${memdb_binary_sourceFiles}" "${memdb_binary_resourceFiles}")
    set_property(TARGET "${BINARY_NAME}" PROPERTY FOLDER "Binaries")
    set_target_properties("${BINARY_NAME}" PROPERTIES OUTPUT_NAME_DEBUG          "${BINARY_NAME_DEBUG}"
                                                      OUTPUT_NAME_RELEASE        "${BINARY_NAME_RELEASE}"
                                                      OUTPUT_NAME_RELWITHDEBINFO "${BINARY_NAME_RELWITHDEBINFO}"
                                                      RUNTIME_OUTPUT_DIRECTORY   "${EXECUTABLE_OUTPUT_PATH}"
                                                      VERSION                    "${memdb_binary_version}" )

    target_include_directories("${BINARY_NAME}" PUBLIC ${memdb_binary_includeDirectories})
    
    #
    # Add header files, library files, and dependecies which are queued and then processed after all targets
    #
    list(FIND memdb_binary_includeDirectories "include" includeIndex)
    if (includeIndex GREATER -1)
        memdb_add_include_directories(target "${BINARY_NAME}" includeDirectories "include")    
        list(REMOVE_ITEM memdb_binary_includeDirectories "include")
    endif()
    memdb_queue_include_directories("${BINARY_NAME}" "${memdb_binary_includeDirectories}")
    memdb_add_link_libraries(target "${BINARY_NAME}" linkLibraries "${memdb_binary_linkLibraries}")
    memdb_add_dependencies(target "${BINARY_NAME}" dependencies "${memdb_binary_dependencies}")
endfunction(memdb_binary)

#
# MEMDB_TEST_BINARY(<baseName> <headerFiles> <sourceFiles> <resourceFiles> <includeDirectories> <linkDirectories>)
#
# GTest and GMock insist on being compiled with the static version of the MSVC runtime libraries, so the test
# executables need to conform.
#
# The <baseName> argument contains base library name to use.  This will be wrapped
# in MemDB specific environment terms.
#
# The <version> argument contains the version number to use.
#
# The <headerFiles> argument contains a list of all the header files for
# this compilation unit.
#
# The <sourceFiles> argument contains a list of all the source files for
# this compilation unit.
#
# The <resourceFiles> argument, optional, contains a list of all the resource files for
# this compilation unit.
#
# The <includeDiretories> argument contains a list of all the header search
# paths for for this compilation unit.
#
# The <linkLibraries> argument, optional, contains a list of all the libraries
# to link with the binary.
#
function(memdb_test_binary)
    set(options)
    set(oneValueArgs baseName version)
    set(multiValueArgs headerFiles sourceFiles resourceFiles includeDirectories linkLibraries dependencies)
    cmake_parse_arguments(memdb_test_binary "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if (DEBUG_CMAKE)
        message("  basename           - ${memdb_test_binary_baseName}")
        message("  version            - ${memdb_test_binary_version}")
        message("  headerFiles        - ${memdb_test_binary_headerFiles}")
        message("  sourceFiles        - ${memdb_test_binary_sourceFiles}")
        message("  resourceFiles      - ${memdb_test_binary_resourceFiles}")
        message("  includeDirectories - ${memdb_test_binary_includeDirectories}")
        message("  linkLibraries      - ${memdb_test_binary_linkLibraries}")
        message("  dependencies       - ${memdb_test_binary_dependencies}")
    endif()
    
    #
    # Create the binary names based on the configuration
    #
    set(BINARY_NAME                "${memdb_test_binary_baseName}")
    set(BINARY_NAME_DEBUG          "${BINARY_NAME}-${MEMDB_TOOLSET}-${MEMDB_ARCH}${RUNTIME_LIBRARY_TYPE}-d-${memdb_test_binary_version}")
    set(BINARY_NAME_RELEASE        "${BINARY_NAME}-${MEMDB_TOOLSET}-${MEMDB_ARCH}${RUNTIME_LIBRARY_TYPE}-${memdb_test_binary_version}")
    set(BINARY_NAME_RELWITHDEBINFO "${BINARY_NAME}-${MEMDB_TOOLSET}-${MEMDB_ARCH}${RUNTIME_LIBRARY_TYPE}-${memdb_test_binary_version}")

    foreach(flag_var
            CMAKE_CXX_FLAGS CMAKE_CXX_FLAGS_DEBUG CMAKE_CXX_FLAGS_RELEASE CMAKE_CXX_FLAGS_RELWITHDEBINFO
           )
            # Replaces /MD with /MT in defaults.
            string(REPLACE "/MD" "/MT" ${flag_var} "${${flag_var}}")
    endforeach()

    #
    # Create the binary
    #
    message(STATUS "Test Binary ${BINARY_NAME} will be built with ${CMAKE_CXX_FLAGS} ${CMAKE_CXX_FLAGS_DEBUG}")
    add_executable("${BINARY_NAME}" "${memdb_test_binary_headerFiles}" "${memdb_test_binary_sourceFiles}" "${memdb_test_binary_resourceFiles}")
    set_property(TARGET "${BINARY_NAME}" PROPERTY FOLDER "Binaries")
    set_target_properties("${BINARY_NAME}" PROPERTIES OUTPUT_NAME_DEBUG          "${BINARY_NAME_DEBUG}"
                                                      OUTPUT_NAME_RELEASE        "${BINARY_NAME_RELEASE}"
                                                      OUTPUT_NAME_RELWITHDEBINFO "${BINARY_NAME_RELWITHDEBINFO}"
                                                      RUNTIME_OUTPUT_DIRECTORY   "${EXECUTABLE_OUTPUT_PATH}"
                                                      VERSION                    "${memdb_test_binary_version}" )

    target_include_directories("${BINARY_NAME}" PUBLIC ${memdb_test_binary_includeDirectories})
    
    #
    # Add header files, library files, and dependencies which are queued and then processed after all targets
    #
    list(FIND memdb_test_binary_includeDirectories "include" includeIndex)
    if (includeIndex GREATER -1)
        memdb_add_include_directories(target "${BINARY_NAME}" includeDirectories "include")    
        list(REMOVE_ITEM memdb_test_binary_includeDirectories "include")
    endif()
    memdb_queue_include_directories("${BINARY_NAME}" "${memdb_test_binary_includeDirectories}")
    memdb_add_link_libraries(target "${BINARY_NAME}" linkLibraries "${memdb_test_binary_linkLibraries}")
    memdb_add_dependencies(target "${BINARY_NAME}" dependencies "${memdb_test_binary_dependencies}")
endfunction(memdb_test_binary)

function(memdb_add_include_directories)
    set(options)
    set(oneValueArgs target)
    set(multiValueArgs includeDirectories)
    cmake_parse_arguments(memdb_add_include_directories "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    
    if(DEFINED memdb_add_include_directories_includeDirectories)
        message(STATUS "${target} - Include Search Directories:")
        foreach(includeDirectory ${memdb_add_include_directories_includeDirectories})     
            if (DEFINED ${includeDirectory})    
                target_include_directories ("${memdb_add_include_directories_target}" PRIVATE "${${includeDirectory}}")  
                message(STATUS "  Include Directory - ${${includeDirectory}}")
            else()
                target_include_directories ("${memdb_add_include_directories_target}" PRIVATE "${includeDirectory}")  
                message(STATUS "  Include Directory - ${includeDirectory}")
            endif()
        endforeach()
    endif()
endfunction(memdb_add_include_directories)

function(memdb_add_link_libraries)
    set(options)
    set(oneValueArgs target)
    set(multiValueArgs linkLibraries)
    cmake_parse_arguments(memdb_add_link_libraries "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    
    if(DEFINED memdb_add_link_libraries_linkLibraries)
        message(STATUS "${target} - Link Libraries:")
        foreach(library ${memdb_add_link_libraries_linkLibraries})     
            if (DEFINED ${library})
                #external project link library
                target_link_libraries ("${memdb_add_link_libraries_target}" "${${library}}")  
                message(STATUS "Link Library - ${${library}}")
            else()
                #internal project link library so link and add dependency
                target_link_libraries ("${memdb_add_link_libraries_target}" "${library}")  
                message(STATUS "Link Library - ${library}")
            endif()
        endforeach()
    endif()
endfunction(memdb_add_link_libraries)

function(memdb_add_dependencies)
    set(options)
    set(oneValueArgs target)
    set(multiValueArgs dependencies)
    cmake_parse_arguments(memdb_add_dependencies "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    
    if(DEFINED memdb_add_dependencies_dependencies)
        message(STATUS "${target} - Project Dependecies:")
        foreach(dependency ${memdb_add_dependencies_dependencies})     
            if( DEFINED ${dependency})         
                add_dependencies("${memdb_add_dependencies_target}" "${${dependency}}")
                message(STATUS "Project Dependency - ${${dependency}}")
            else()
               add_dependencies("${memdb_add_dependencies_target}" "${dependency}")
               message(STATUS "Project Dependency - ${dependency}")
            endif()
        endforeach()
    endif()
endfunction(memdb_add_dependencies)

macro(memdb_queue_include_directories target include_directories)
    file(APPEND "${TARGET_INCLUDE_DIRECTORIES_FILE}" "${target};")
    file(APPEND "${TARGET_INCLUDE_DIRECTORIES_FILE}" "${include_directories}\n")
endmacro()

macro(memdb_dereference_targets)
    # process the include directories file
    file(STRINGS "${TARGET_INCLUDE_DIRECTORIES_FILE}" target_include_directories_list)
    foreach(target_include_directories ${target_include_directories_list})
        #pull off the target value
        list(GET target_include_directories 0 target)
        list(REMOVE_AT target_include_directories 0)
        #message("${target} - ${target_include_directories}")
        memdb_add_include_directories(target "${target}" includeDirectories "${target_include_directories}")
    endforeach()    
endmacro()
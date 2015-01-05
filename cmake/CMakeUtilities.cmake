#
# Copyright 2014 Qbase, LLC.
#
# CMake functions for building libraries and binaries
#
include(CMakeParseArguments)
include(CheckCXXCompilerFlag)
include(PrefixFiles)

macro(append_flag flag)
    check_cxx_compiler_flag("${flag}" HAVE_FLAG_${flag})

    if(HAVE_FLAG_${flag})
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${flag}")
    endif()
endmacro()

macro(fix_default_settings)
    #
    # If it wasn't specified, set the default build type to Release.
    #
    if(NOT CMAKE_BUILD_TYPE)
        set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Choose the type of build, options are: None Debug Release." FORCE)
    endif()

    if (MSVC)
        set(MSVC_STATIC_RUNTIME ON CACHE BOOL "Link with MSVC static runtime.")
        
        #
        # For MSVC, CMake sets certain flags to defaults we want to override.
        #
        foreach(flag_var
                CMAKE_CXX_FLAGS
               )
#            if(BUILD_SHARED_LIB)
#                set(RUNTIME_LIBRARY_TYPE "-md" CACHE STRING "Type of runtime MSVC runtime library that was linked.")
#            else()
#                string(REPLACE "/MD" "/MT" ${flag_var} "${${flag_var}}")
#               set(RUNTIME_LIBRARY_TYPE "-mt" CACHE STRING "Type of runtime MSVC runtime library that was linked.")
#                set(MSVC_STATIC_RUNTIME ON CACHE BOOL "Link with MSVC static runtime.")
#            endif()

            append_flag("/MP")

            # Replaces /W3 with /W4 in defaults.
            string(REPLACE "/W3" "/W4" ${flag_var} "${${flag_var}}")
        endforeach()

        #set release and release with debug info flags
        set(CMAKE_CXX_FLAGS_RELEASE "/MD /Ox /Ob2 /Ot /Oy /D NDEBUG")
        set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "/MD /Zi /Ox /Ob2 /Ot /Oy")     
        
#        set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /GL")
#        set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE} /LTCG")
#        set(CMAKE_SHARED_LINKER_FLAGS_RELEASE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE} /LTCG")
#        set(CMAKE_MODULE_LINKER_FLAGS_RELEASE "${CMAKE_MODULE_LINKER_FLAGS_RELEASE} /LTCG")

        append_flag("-DWIN32_LEAN_AND_MEAN")

        #
        # Change the default number of file descriptors for sockets, the 
        # default for Windows is 64
        #
        append_flag("-DFD_SETSIZE=1024")
    else()
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
# TODO: Enable this line when cmake recognizes this flag -- append_flag("-std=c++11")
        append_flag("-Wall")
        append_flag("-pipe")
        append_flag(-fstack-protector -Wl,-z,relro -Wl,-z,now -Wformat-security)
        append_flag(-fvisibility=hidden)
        append_flag(-Wpointer-arith)
        append_flag(-Wformat-nonliteral)
        append_flag(-Winit-self)

        set(RUNTIME_LIBRARY_TYPE "" CACHE STRING "Type of runtime MSVC runtime library that was linked.")        
    endif()
endmacro()

#
# static_library( <baseName> <version>
#                 <headerFiles> <sourceFiles> <resourceFiles>
#                 <includeDirectories> <explicitLinkLang>)
#
# The <baseName> argument contains the base library name to use.  This will be wrapped
# in specific environment terms.
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
function(static_library)
    set(options)
    set(oneValueArgs baseName version explicitLinkLang)
    set(multiValueArgs headerFiles sourceFiles resourceFiles includeDirectories dependencies)
    cmake_parse_arguments(static_library "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    
    if (DEBUG_CMAKE)
        message("basename           - ${static_library_baseName}")
        message("version            - ${static_library_version}")
        message("headerFiles        - ${static_library_headerFiles}")
        message("sourceFiles        - ${static_library_sourceFiles}")
        message("resourceFiles      - ${static_library_resourceFiles}")
        message("includeDirectories - ${static_library_includeDirectories}")
        message("dependencies       - ${static_library_dependencies}")
        message("explicitLinkLang   - ${static_library_explicitLinkLang}")
    endif()

    #
    # Create the library names based on the configuration
    #
    #
    set(LIBRARY_NAME                "${static_library_baseName}")
    set(LIBRARY_NAME_DEBUG          "${LIBRARY_NAME}-${TOOLSET}-${ARCH}${RUNTIME_LIBRARY_TYPE}-d-${static_library_version}")
    set(LIBRARY_NAME_RELEASE        "${LIBRARY_NAME}-${TOOLSET}-${ARCH}${RUNTIME_LIBRARY_TYPE}-${static_library_version}")
    set(LIBRARY_NAME_RELWITHDEBINFO "${LIBRARY_NAME}-${TOOLSET}-${ARCH}${RUNTIME_LIBRARY_TYPE}-${shared_library_version}")
        
    set(${LIBRARY_NAME}_include_dir "${CMAKE_CURRENT_SOURCE_DIR}/include" CACHE STRING "Include directory for ${LIBRARY_NAME}.")
    
    #
    # Create the static library
    #
    message(STATUS "Library ${LIBRARY_NAME} will be built with ${CMAKE_CXX_FLAGS}")
    add_library("${LIBRARY_NAME}" STATIC "${static_library_headerFiles}" "${static_library_sourceFiles}" "${static_library_resourceFiles}")
    set_target_properties("${LIBRARY_NAME}" PROPERTIES FOLDER "Libraries"
                                                       OUTPUT_NAME_DEBUG          "${LIBRARY_NAME_DEBUG}"
                                                       OUTPUT_NAME_RELEASE        "${LIBRARY_NAME_RELEASE}"
                                                       OUTPUT_NAME_RELWITHDEBINFO "${LIBRARY_NAME_RELWITHDEBINFO}"
                                                       RUNTIME_OUTPUT_DIRECTORY   "${LIBRARY_OUTPUT_PATH}"
                                                       VERSION                    "${static_library_version}" )

    #
    # Add header files, library files, and dependecies which are queued and then processed after all targets
    #
    list(FIND static_library_includeDirectories "include" includeIndex)
    if (includeIndex GREATER -1)
        add_include_directories(target "${LIBRARY_NAME}" includeDirectories "include")    
        list(REMOVE_ITEM static_library_includeDirectories "include")
    endif()
    queue_include_directories("${LIBRARY_NAME}" "${static_library_includeDirectories}")
    add_dependencies(target "${LIBRARY_NAME}" dependencies "${static_library_dependencies}")                                                      
                                                       
    if( DEFINED static_library_explicitLinkLang )
        set_target_properties("${LIBRARY_NAME}" PROPERTIES LINKER_LANGUAGE CXX)
    endif()
endfunction(static_library)

#
# shared_library( <baseName> <version> <soversion>
#                 <headerFiles> <sourceFiles> <resourceFiles>
#                 <includeDirectories> <explicitLinkLang>)
#
# The <baseName> argument contains the base library name to use.  This will be wrapped
# in specific environment terms.
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
function(shared_library)
    set(options)
    set(oneValueArgs baseName version soversion explicitLinkLang)
    set(multiValueArgs headerFiles sourceFiles resourceFiles includeDirectories dependencies)
    cmake_parse_arguments(shared_library "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    
    if (DEFINED DEBUG_CMAKE)
        message("basename           - ${shared_library_baseName}")
        message("version            - ${shared_library_version}")
        message("soversion          - ${shared_library_soversion}")
        message("headerFiles        - ${shared_library_headerFiles}")
        message("sourceFiles        - ${shared_library_sourceFiles}")
        message("resourceFiles      - ${shared_library_resourceFiles}")
        message("includeDirectories - ${shared_library_includeDirectories}")
        message("dependencies       - ${binary_dependencies}")
        message("explicitLinkLang   - ${shared_library_explicitLinkLang}")
    endif()

    #
    # Create the library names based on the configuration
    #
    #
    set(LIBRARY_NAME                "${shared_library_baseName}")
    set(LIBRARY_NAME_DEBUG          "${LIBRARY_NAME}-${TOOLSET}-${ARCH}${RUNTIME_LIBRARY_TYPE}-d-${shared_library_version}")
    set(LIBRARY_NAME_RELEASE        "${LIBRARY_NAME}-${TOOLSET}-${ARCH}${RUNTIME_LIBRARY_TYPE}-${shared_library_version}")
    set(LIBRARY_NAME_RELWITHDEBINFO "${LIBRARY_NAME}-${TOOLSET}-${ARCH}${RUNTIME_LIBRARY_TYPE}-${shared_library_version}")
    
    set("${LIBRARY_NAME}_include_dir" "${CMAKE_CURRENT_SOURCE_DIR}/include" CACHE STRING "Include directory for ${LIBRARY_NAME}.")

    #
    # Create the shared library
    #
    message(STATUS "Library ${LIBRARY_NAME} will be built with ${CMAKE_CXX_FLAGS}")
    add_library("${LIBRARY_NAME}" SHARED "${shared_library_headerFiles}" "${shared_library_sourceFiles}" "${shared_library_resourceFiles}")
    set_property(TARGET "${LIBRARY_NAME}" PROPERTY FOLDER "Libraries")
    set_target_properties("${LIBRARY_NAME}" PROPERTIES DEFINE_SYMBOL              "COMPILING_DLL"
                                                       OUTPUT_NAME_DEBUG          "${LIBRARY_NAME_DEBUG}"
                                                       OUTPUT_NAME_RELEASE        "${LIBRARY_NAME_RELEASE}"
                                                       OUTPUT_NAME_RELWITHDEBINFO "${LIBRARY_NAME_RELWITHDEBINFO}"
                                                       RUNTIME_OUTPUT_DIRECTORY   "${EXECUTABLE_OUTPUT_PATH}"
                                                       SOVERSION                  "${shared_library_soversion}"
                                                       VERSION                    "${shared_library_version}" )
       
    
    #
    # Add header files, library files, and dependecies which are queued and then processed after all targets
    #
    list(FIND shared_library_includeDirectories "include" includeIndex)
    if (includeIndex GREATER -1)
        add_include_directories(target "${LIBRARY_NAME}" includeDirectories "include")    
        list(REMOVE_ITEM shared_library_includeDirectories "include")
    endif()
    queue_include_directories("${LIBRARY_NAME}" "${shared_library_includeDirectories}")
    add_dependencies(target "${LIBRARY_NAME}" dependencies "${shared_library_dependencies}") 

    if( DEFINED shared_library_explicitLinkLang )
        set_target_properties("${LIBRARY_NAME}" PROPERTIES LINKER_LANGUAGE CXX
                                                           IMPORT_SUFFIX "_imp.lib")
    endif()
endfunction(shared_library)

#
# CREATE_BINARY(<baseName> <headerFiles> <sourceFiles> <resourceFiles> <includeDirectories> <linkDirectories>)
#
# The <baseName> argument contains base library name to use.  This will be wrapped
# in specific environment terms.
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
function(create_binary)
    set(options)
    set(oneValueArgs baseName version)
    set(multiValueArgs headerFiles sourceFiles resourceFiles includeDirectories linkLibraries dependencies)
    cmake_parse_arguments(create_binary "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if (DEBUG_CMAKE)
        message("  basename           - ${create_binary_baseName}")
        message("  version            - ${create_binary_version}")
        message("  headerFiles        - ${create_binary_headerFiles}")
        message("  sourceFiles        - ${create_binary_sourceFiles}")
        message("  resourceFiles      - ${create_binary_resourceFiles}")
        message("  includeDirectories - ${create_binary_includeDirectories}")
        message("  linkLibraries      - ${create_binary_linkLibraries}")
        message("  dependencies       - ${create_binary_dependencies}")
    endif()
    
    #
    # Create the binary names based on the configuration
    #
    set(BINARY_NAME_BASE           "${create_binary_baseName}")
    set(BINARY_NAME_DEBUG          "${BINARY_NAME_BASE}-${TOOLSET}-${ARCH}${RUNTIME_LIBRARY_TYPE}-d-${create_binary_version}")
    set(BINARY_NAME_RELEASE        "${BINARY_NAME_BASE}-${TOOLSET}-${ARCH}${RUNTIME_LIBRARY_TYPE}-${create_binary_version}")
    set(BINARY_NAME_RELWITHDEBINFO "${BINARY_NAME_BASE}-${TOOLSET}-${ARCH}${RUNTIME_LIBRARY_TYPE}-${create_binary_version}")
    
    #
    # Create the static library
    #
    message(STATUS "Binary ${BINARY_NAME_BASE} will be built with ${CMAKE_CXX_FLAGS}")
    add_executable("${BINARY_NAME_BASE}" "${create_binary_headerFiles}" "${create_binary_sourceFiles}" "${create_binary_resourceFiles}")
    set_property(TARGET "${BINARY_NAME_BASE}" PROPERTY FOLDER "Binaries")
    set_target_properties("${BINARY_NAME_BASE}" PROPERTIES OUTPUT_NAME_DEBUG     "${BINARY_NAME_DEBUG}"
                                                      OUTPUT_NAME_RELEASE        "${BINARY_NAME_RELEASE}"
                                                      OUTPUT_NAME_RELWITHDEBINFO "${BINARY_NAME_RELWITHDEBINFO}"
                                                      RUNTIME_OUTPUT_DIRECTORY   "${EXECUTABLE_OUTPUT_PATH}"
                                                      VERSION                    "${binary_version}" )    
    #
    # Add header files, library files, and dependencies which are queued and then processed after all targets
    #
    list(FIND create_binary_includeDirectories "include" includeIndex)
    if (includeIndex GREATER -1)
        add_include_directories(target "${BINARY_NAME_BASE}" includeDirectories "include")    
        list(REMOVE_ITEM create_binary_includeDirectories "include")
    endif()
    queue_include_directories("${BINARY_NAME_BASE}" "${create_binary_includeDirectories}")
    add_link_libraries(target "${BINARY_NAME_BASE}" linkLibraries "${create_binary_linkLibraries}")
    add_dependencies(target "${BINARY_NAME_BASE}" dependencies "${create_binary_dependencies}")
endfunction(create_binary)

function(add_include_directories)
    set(options)
    set(oneValueArgs target)
    set(multiValueArgs includeDirectories)
    cmake_parse_arguments(add_include_directories "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    
    if(DEFINED add_include_directories_includeDirectories)
        message(STATUS "${add_include_directories_target} - Include Search Directories:")
        foreach(includeDirectory ${add_include_directories_includeDirectories})     
            if (DEFINED ${includeDirectory})    
                target_include_directories ("${add_include_directories_target}" PRIVATE "${${includeDirectory}}")  
                message(STATUS "Include Directory - ${${includeDirectory}}")
            else()
                target_include_directories ("${add_include_directories_target}" PRIVATE "${includeDirectory}")  
                message(STATUS "Include Directory - ${includeDirectory}")
            endif()
        endforeach()
    endif()
endfunction(add_include_directories)

function(add_link_libraries)
    set(options)
    set(oneValueArgs target)
    set(multiValueArgs linkLibraries)
    cmake_parse_arguments(add_link_libraries "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    
    if(DEFINED add_link_libraries_linkLibraries)
        message(STATUS "${add_link_libraries_target} - Link Libraries:")
        foreach(library ${add_link_libraries_linkLibraries})     
            if (DEFINED ${library})
                #external project link library
                target_link_libraries ("${add_link_libraries_target}" "${${library}}")  
                message(STATUS "Link Library - ${${library}}")
            else()
                #internal project link library so link and add dependency
                target_link_libraries ("${add_link_libraries_target}" "${library}")  
                message(STATUS "Link Library - ${library}")
            endif()
        endforeach()
    endif()
endfunction(add_link_libraries)

function(add_dependencies)
    set(options)
    set(oneValueArgs target)
    set(multiValueArgs dependencies)
    cmake_parse_arguments(add_dependencies "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    
    if(DEFINED add_dependencies_dependencies)
        message(STATUS "${add_dependencies_target} - Project Dependecies:")
        foreach(dependency ${add_dependencies_dependencies})     
            if( DEFINED ${dependency})         
                add_dependencies("${add_dependencies_target}" "${${dependency}}")
                message(STATUS "Project Dependency - ${${dependency}}")
            else()
               add_dependencies("${add_dependencies_target}" "${dependency}")
               message(STATUS "Project Dependency - ${dependency}")
            endif()
        endforeach()
    endif()
endfunction(add_dependencies)

macro(queue_include_directories target include_directories)
    file(APPEND "${TARGET_INCLUDE_DIRECTORIES_FILE}" "${target};")
    file(APPEND "${TARGET_INCLUDE_DIRECTORIES_FILE}" "${include_directories}\n")
endmacro()

macro(dereference_targets)
    # process the include directories file
    file(STRINGS "${TARGET_INCLUDE_DIRECTORIES_FILE}" target_include_directories_list)
    foreach(target_include_directories ${target_include_directories_list})
        #pull off the target value
        list(GET target_include_directories 0 target)
        list(REMOVE_AT target_include_directories 0)
        #message("${target} - ${target_include_directories}")
        add_include_directories(target "${target}" includeDirectories "${target_include_directories}")
    endforeach()    
endmacro()
#
# Detect the compiler and name it
#
macro(DetermineToolchainName)
    message(STATUS "Determining Toolchain Name")

    if( ${CMAKE_CXX_COMPILER_ID} STREQUAL Intel)
        set(TOOLSET intel)
    elseif( ${CMAKE_CXX_COMPILER_ID} STREQUAL GNU)
        set(TOOLSET gnu)
    elseif (${CMAKE_CXX_COMPILER_ID} STREQUAL MSVC)
        set(TOOLSET vc)
    else()
        message(FATAL_ERROR "  Unable to determine compiler toolchain acronym.")
    endif()

    message(STATUS "  Compiler Toolchain Acronym is \"${TOOLSET}\"")
    message(STATUS "Determining Toolchain Name - Done")   
endmacro()

DetermineToolchainName()

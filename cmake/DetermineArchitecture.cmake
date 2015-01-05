#
# Detect the compiler architecture and name it
#
macro(DetermineArchitecture)
    message(STATUS "Determining Toolchain Architecture")

    if( CMAKE_SIZEOF_VOID_P EQUAL 8 )
        MESSAGE(STATUS "  64 bit compiler detected")
        SET(ARCH "x64")
        SET(LIB_OUTPUT_DIRECTORY "lib64")
        SET(BIN_OUTPUT_DIRECTORY "bin64")
    else( CMAKE_SIZEOF_VOID_P EQUAL 4 )
        MESSAGE(STATUS "  32 bit compiler detected")
        SET(ARCH "x86")
        SET(LIB_OUTPUT_DIRECTORY "lib32")
        SET(BIN_OUTPUT_DIRECTORY "bin32")
    endif( CMAKE_SIZEOF_VOID_P EQUAL 8 )

    message(STATUS "  Compiler Toolchain Achitecture is \"${ARCH}\"")
    message(STATUS "Determining Toolchain Architecture - Done")
endmacro()

DetermineArchitecture()

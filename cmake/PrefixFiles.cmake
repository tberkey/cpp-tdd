#
# Copyright 2014 Qbase, LLC.
#
# MemDB CMake function to prepend a path to files.
#

#
# prefix_files(<files> <prefix>)
#
# The <files> argument contains a list of all the source files for
# this compilation unit.
#
# The <prefix> argument is a string (path) that is prepended to every file
# the <files> list.
#
function(prefix_files files prefix )
    foreach( file ${${files}} )
        set( MODIFIED ${MODIFIED} ${prefix}/${file} )
    endforeach()

    set( ${files} ${MODIFIED} PARENT_SCOPE )
endfunction()

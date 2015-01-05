unset(projects)

# czmq
list(APPEND projects czmq)
set(CZMQ_PROJECT "czmq" CACHE STRING "CMZQ external project")
set(czmq_version "master")
set(czmq_git_repository "https://github.com/tberkey/czmq.git")
set(czmq_git_tag "origin/master")

# gmock
list(APPEND projects gmock)
set(GMOCK_PROJECT "gmock" CACHE STRING "GMock external project")
set(gmock_version "1.7.0")
set(gmock_url "https://googlemock.googlecode.com/files/gmock-${gmock_version}.zip")
set(gmock_md5 "073b984d8798ea1594f5e44d85b20d66")

# memdb
list(APPEND projects memdb)
set(MEMDB_PROJECT "memdb" CACHE STRING "MemDB external project")
set(memdb_version "master")
set(memdb_git_repository "https://github.com/tberkey/MemDB.git")
set(memdb_git_tag "origin/master")

# zeromq
list(APPEND projects zeromq CACHE STRING "ZeroMQ external project")
set(ZEROMQ_PROJECT "zmq")
set(zeromq_version "master")
set(zeromq_git_repository "https://github.com/tberkey/libzmq.git")
set(zeromq_git_tag "origin/master")

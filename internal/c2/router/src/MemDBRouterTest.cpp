#include <gmock/gmock.h>

#include <memdb.h>

TEST(MemDBRouter, ZactorInstantiation)
{ 
    zactor_t* server = zactor_new(memdb_server, "memdb_server");

    EXPECT_TRUE(server != nullptr);
    
    zactor_destroy(&server);

    EXPECT_TRUE(server == nullptr);
}

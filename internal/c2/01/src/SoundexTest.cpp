#include <gmock/gmock.h>

#include <Soundex.hpp>

using namespace testing;

class SoundexEncoding : public Test
{
    public:
        Soundex soundex;
};

TEST_F(SoundexEncoding, RetainsSoleLetterOfOneLetterWord)
{ 
   ASSERT_THAT(soundex.Encode("A"), Eq("A000"));
}

TEST_F(SoundexEncoding, PadsWithZerosToEnsureThreeDigits)
{
    ASSERT_THAT(soundex.Encode("I"), Eq("I000"));
}
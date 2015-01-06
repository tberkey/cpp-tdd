#ifndef SOUNDEX_HPP_1CA06766_77AA_47CF_82C6_875764FF46E4
#define SOUNDEX_HPP_1CA06766_77AA_47CF_82C6_875764FF46E4

#include <string>

class Soundex
{
    public:
    std::string Encode(const std::string& word) const
    {
        return ZeroPad(word);
    }

    private:
    std::string ZeroPad(const std::string& word) const
    {
        return word + "000";
    }
};


#endif // SOUNDEX_HPP_1CA06766_77AA_47CF_82C6_875764FF46E4

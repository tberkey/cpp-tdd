#ifndef SOUNDEX_HPP_1CA06766_77AA_47CF_82C6_875764FF46E4
#define SOUNDEX_HPP_1CA06766_77AA_47CF_82C6_875764FF46E4

#include <string>

class Soundex
{
    public:
        std::string Encode(const std::string& word) const
        {
            return ZeroPad(Head(word) + EncodedDigits(word));
        }

    private:
        static const size_t maxCodeLength{ 4 };

        std::string Head(const std::string& word) const
        {
            return word.substr(0, 1);
        }

        std::string EncodedDigits(const std::string& word) const
        {
            if(word.length() > 1)
            {
                return EncodeDigit();
            }

            return "";
        }

        std::string EncodeDigit() const
        {
            return "1";
        }

        std::string ZeroPad(const std::string& word) const
        {
            std::string::size_type zerosNeeded = maxCodeLength - word.length();
            return word + std::string(zerosNeeded, '0');
        }
};


#endif // SOUNDEX_HPP_1CA06766_77AA_47CF_82C6_875764FF46E4

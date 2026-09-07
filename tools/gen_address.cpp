#include <iostream>
#include "crypto/crypto.h"
#include "CryptoNote.h"
#include "Utilities/Addresses.h"
#include "config/CryptoNoteConfig.h"
#include "Common/StringTools.h"

int main() {
    Crypto::PublicKey spendPublic;
    Crypto::SecretKey spendSecret;
    Crypto::generate_keys(spendPublic, spendSecret);

    Crypto::SecretKey viewSecret;
    Crypto::PublicKey viewPublic;
    Crypto::crypto_ops::generateViewFromSpend(spendSecret, viewSecret, viewPublic);

    CryptoNote::AccountPublicAddress addr;
    addr.spendPublicKey = spendPublic;
    addr.viewPublicKey = viewPublic;

    std::string address = Utilities::getAccountAddressAsStr(
        CryptoNote::parameters::CRYPTONOTE_PUBLIC_ADDRESS_BASE58_PREFIX, addr);

    std::cout << "Address: " << address << std::endl;
    std::cout << "Spend Secret Key: " << Common::podToHex(spendSecret) << std::endl;
    std::cout << "Spend Public Key: " << Common::podToHex(spendPublic) << std::endl;
    std::cout << "View Secret Key: " << Common::podToHex(viewSecret) << std::endl;
    std::cout << "View Public Key: " << Common::podToHex(viewPublic) << std::endl;
    return 0;
}


#include <iostream>
#include <memory>
#include "CryptoNoteCore/Currency.h"
#include "Logging/ConsoleLogger.h"

int main() {
    std::shared_ptr<Logging::ILogger> logger = std::make_shared<Logging::ConsoleLogger>();
    CryptoNote::CurrencyBuilder builder(logger);
    CryptoNote::Currency currency = builder.currency();
    std::cout << "founderBonusHeight=" << currency.founderBonusHeight()
              << " founderBonusAmount=" << currency.founderBonusAmount() << std::endl;

    uint64_t reward;
    int64_t emissionChange;
    uint64_t alreadyGenerated = 0;

    for (uint32_t h = 0; h <= 3; h++) {
        bool ok = currency.getBlockReward(1, 100000, 100, alreadyGenerated, 0, reward, emissionChange, h);
        std::cout << "height=" << h << " ok=" << ok
                  << " reward(raw)=" << reward
                  << " reward(MDZ)=" << (double)reward / 100.0
                  << " alreadyGenerated(before)=" << alreadyGenerated << std::endl;
        alreadyGenerated += reward;
    }
    return 0;
}

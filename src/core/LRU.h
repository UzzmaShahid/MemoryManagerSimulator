#ifndef LRU_H
#define LRU_H

#include "Algorithm.h"

class LRU : public Algorithm {
public:
    int selectVictim(const std::vector<int>& memory,
                    const std::vector<int>& loadOrder,
                    const std::vector<int>& accessTimes) override;
    const char* getName() const override { return "LRU"; }
};

#endif

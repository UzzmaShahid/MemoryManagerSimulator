#ifndef FIFO_H
#define FIFO_H

#include "Algorithm.h"

class FIFO : public Algorithm {
public:
    int selectVictim(const std::vector<int>& memory,
                    const std::vector<int>& loadOrder,
                    const std::vector<int>& accessTimes) override;
    const char* getName() const override { return "FIFO"; }
};

#endif

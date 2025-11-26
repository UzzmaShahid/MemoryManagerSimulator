#ifndef ALGORITHM_H
#define ALGORITHM_H

#include <vector>

class Algorithm {
public:
    virtual ~Algorithm() = default;
    virtual int selectVictim(const std::vector<int>& memory,
                           const std::vector<int>& loadOrder,
                           const std::vector<int>& accessTimes) = 0;
    virtual const char* getName() const = 0;
};

#endif

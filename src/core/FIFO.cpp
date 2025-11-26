#include "FIFO.h"
#include <cstddef>

int FIFO::selectVictim(const std::vector<int>& memory,
                      const std::vector<int>& loadOrder,
                      const std::vector<int>& accessTimes) {
    int oldestTime = 999999;
    int victimFrame = 0;
    
    for (std::size_t i = 0; i < memory.size(); i++) {
        if (memory[i] != -1 && loadOrder[i] < oldestTime) {
            oldestTime = loadOrder[i];
            victimFrame = i;
        }
    }
    return victimFrame;
}

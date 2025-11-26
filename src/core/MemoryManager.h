#ifndef MEMORYMANAGER_H
#define MEMORYMANAGER_H

#include <vector>
#include <string>
#include "PageTable.h"
#include "Algorithm.h"

struct Statistics {
    int totalAccesses = 0;
    int pageFaults = 0;
    int hits = 0;
    int replacements = 0;
    
    double getHitRate() const {
        return totalAccesses > 0 ? (hits * 100.0 / totalAccesses) : 0.0;
    }
};

class MemoryManager {
private:
    std::vector<int> physicalMemory;
    std::vector<int> loadOrder;
    std::vector<int> accessTimes;
    PageTable pageTable;
    Algorithm* algorithm;
    Statistics stats;
    int totalFrames;
    int currentTime;

public:
    MemoryManager(int frames, int pages, Algorithm* algo);
    std::string accessPage(int pageNum);
    void reset();
    
    // Getters
    const std::vector<int>& getPhysicalMemory() const { return physicalMemory; }
    const Statistics& getStatistics() const { return stats; }
    const PageTable& getPageTable() const { return pageTable; }
    int getTotalFrames() const { return totalFrames; }
};

#endif

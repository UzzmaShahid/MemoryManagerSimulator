#include "MemoryManager.h"
#include <sstream>
#include <algorithm>

MemoryManager::MemoryManager(int frames, int pages, Algorithm* algo)
    : pageTable(pages), algorithm(algo), totalFrames(frames), currentTime(0) {
    physicalMemory.resize(frames, -1);
    loadOrder.resize(frames, 0);
    accessTimes.resize(frames, 0);
}

std::string MemoryManager::accessPage(int pageNum) {
    std::ostringstream result;
    stats.totalAccesses++;
    currentTime++;
    
    // Check if page is in memory
    if (pageTable.isValid(pageNum)) {
        // HIT
        stats.hits++;
        int frameNum = pageTable.getFrameNumber(pageNum);
        accessTimes[frameNum] = currentTime;
        pageTable.updateAccessTime(pageNum, currentTime);
        result << "HIT: Page " << pageNum << " found in Frame " << frameNum;
        return result.str();
    }
    
    // PAGE FAULT
    stats.pageFaults++;
    
    // Find free frame
    auto it = std::find(physicalMemory.begin(), physicalMemory.end(), -1);
    
    if (it != physicalMemory.end()) {
        // Free frame available
        int frameNum = std::distance(physicalMemory.begin(), it);
        physicalMemory[frameNum] = pageNum;
        loadOrder[frameNum] = currentTime;
        accessTimes[frameNum] = currentTime;
        pageTable.setMapping(pageNum, frameNum, currentTime);
        result << "PAGE FAULT: Page " << pageNum << " loaded into Frame " << frameNum;
    } else {
        // Need replacement
        stats.replacements++;
        int victimFrame = algorithm->selectVictim(physicalMemory, loadOrder, accessTimes);
        int victimPage = physicalMemory[victimFrame];
        
        // Remove victim
        pageTable.invalidate(victimPage);
        
        // Load new page
        physicalMemory[victimFrame] = pageNum;
        loadOrder[victimFrame] = currentTime;
        accessTimes[victimFrame] = currentTime;
        pageTable.setMapping(pageNum, victimFrame, currentTime);
        
        result << "REPLACEMENT: Page " << pageNum << " replaced Page " 
               << victimPage << " in Frame " << victimFrame;
    }
    
    return result.str();
}

void MemoryManager::reset() {
    std::fill(physicalMemory.begin(), physicalMemory.end(), -1);
    std::fill(loadOrder.begin(), loadOrder.end(), 0);
    std::fill(accessTimes.begin(), accessTimes.end(), 0);
    
    for (int i = 0; i < pageTable.getTotalPages(); i++) {
        pageTable.invalidate(i);
    }
    
    stats = Statistics();
    currentTime = 0;
}

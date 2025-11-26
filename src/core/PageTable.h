#ifndef PAGETABLE_H
#define PAGETABLE_H

#include <vector>
#include "Page.h"

class PageTable {
private:
    std::vector<Page> pages;
    int totalPages;

public:
    PageTable(int numPages);
    Page& getPage(int pageNum);
    bool isValid(int pageNum) const;
    int getFrameNumber(int pageNum) const;
    void setMapping(int pageNum, int frameNum, int time);
    void invalidate(int pageNum);
    void updateAccessTime(int pageNum, int time);
    int getTotalPages() const { return totalPages; }
};

#endif

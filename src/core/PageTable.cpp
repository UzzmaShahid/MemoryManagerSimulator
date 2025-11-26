#include "PageTable.h"

PageTable::PageTable(int numPages) : totalPages(numPages) {
    for (int i = 0; i < numPages; i++) {
        pages.push_back(Page(i));
    }
}

Page& PageTable::getPage(int pageNum) {
    return pages[pageNum];
}

bool PageTable::isValid(int pageNum) const {
    return pages[pageNum].isValid();
}

int PageTable::getFrameNumber(int pageNum) const {
    return pages[pageNum].getFrameNumber();
}

void PageTable::setMapping(int pageNum, int frameNum, int time) {
    pages[pageNum].setFrameNumber(frameNum);
    pages[pageNum].setValid(true);
    pages[pageNum].setLastAccessTime(time);
    pages[pageNum].setLoadTime(time);
}

void PageTable::invalidate(int pageNum) {
    pages[pageNum].setValid(false);
    pages[pageNum].setFrameNumber(-1);
}

void PageTable::updateAccessTime(int pageNum, int time) {
    pages[pageNum].setLastAccessTime(time);
}

#ifndef PAGE_H
#define PAGE_H

class Page {
private:
    int pageNumber;
    int frameNumber;
    bool valid;
    bool dirty;
    int lastAccessTime;
    int loadTime;

public:
    Page(int pageNum);
    
    // Getters
    int getPageNumber() const { return pageNumber; }
    int getFrameNumber() const { return frameNumber; }
    bool isValid() const { return valid; }
    bool isDirty() const { return dirty; }
    int getLastAccessTime() const { return lastAccessTime; }
    int getLoadTime() const { return loadTime; }
    
    // Setters
    void setFrameNumber(int frame) { frameNumber = frame; }
    void setValid(bool v) { valid = v; }
    void setDirty(bool d) { dirty = d; }
    void setLastAccessTime(int time) { lastAccessTime = time; }
    void setLoadTime(int time) { loadTime = time; }
};

#endif

#include "Page.h"

Page::Page(int pageNum) 
    : pageNumber(pageNum), frameNumber(-1), valid(false), 
      dirty(false), lastAccessTime(0), loadTime(0) {}

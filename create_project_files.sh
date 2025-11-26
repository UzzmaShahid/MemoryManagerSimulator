#!/bin/bash

# CMakeLists.txt
cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.10)
project(MemoryManager)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)

find_package(Qt5 COMPONENTS Widgets REQUIRED)

include_directories(src/core src/gui)

set(SOURCES
    src/main.cpp
    src/core/Page.cpp
    src/core/PageTable.cpp
    src/core/MemoryManager.cpp
    src/core/FIFO.cpp
    src/core/LRU.cpp
    src/gui/MainWindow.cpp
)

add_executable(MemoryManager ${SOURCES})
target_link_libraries(MemoryManager Qt5::Widgets)
EOF

# Page.h
cat > src/core/Page.h << 'EOF'
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
EOF

# Page.cpp
cat > src/core/Page.cpp << 'EOF'
#include "Page.h"

Page::Page(int pageNum) 
    : pageNumber(pageNum), frameNumber(-1), valid(false), 
      dirty(false), lastAccessTime(0), loadTime(0) {}
EOF

# PageTable.h
cat > src/core/PageTable.h << 'EOF'
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
EOF

# PageTable.cpp
cat > src/core/PageTable.cpp << 'EOF'
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
EOF

# Algorithm.h
cat > src/core/Algorithm.h << 'EOF'
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
EOF

# FIFO.h
cat > src/core/FIFO.h << 'EOF'
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
EOF

# FIFO.cpp
cat > src/core/FIFO.cpp << 'EOF'
#include "FIFO.h"

int FIFO::selectVictim(const std::vector<int>& memory,
                      const std::vector<int>& loadOrder,
                      const std::vector<int>& accessTimes) {
    int oldestTime = 999999;
    int victimFrame = 0;
    
    for (size_t i = 0; i < memory.size(); i++) {
        if (memory[i] != -1 && loadOrder[i] < oldestTime) {
            oldestTime = loadOrder[i];
            victimFrame = i;
        }
    }
    return victimFrame;
}
EOF

# LRU.h
cat > src/core/LRU.h << 'EOF'
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
EOF

# LRU.cpp
cat > src/core/LRU.cpp << 'EOF'
#include "LRU.h"

int LRU::selectVictim(const std::vector<int>& memory,
                     const std::vector<int>& loadOrder,
                     const std::vector<int>& accessTimes) {
    int oldestTime = 999999;
    int victimFrame = 0;
    
    for (size_t i = 0; i < memory.size(); i++) {
        if (memory[i] != -1 && accessTimes[i] < oldestTime) {
            oldestTime = accessTimes[i];
            victimFrame = i;
        }
    }
    return victimFrame;
}
EOF

# MemoryManager.h
cat > src/core/MemoryManager.h << 'EOF'
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
EOF

# MemoryManager.cpp
cat > src/core/MemoryManager.cpp << 'EOF'
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
EOF

echo "Core files created successfully!"
echo "Now creating GUI files..."

# MainWindow.h (Part 1 - will continue in next message due to length)
cat > src/gui/MainWindow.h << 'EOF'
#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QLabel>
#include <QPushButton>
#include <QComboBox>
#include <QTextEdit>
#include <QTimer>
#include <vector>
#include "MemoryManager.h"
#include "FIFO.h"
#include "LRU.h"

class MainWindow : public QMainWindow {
    Q_OBJECT

private:
    MemoryManager* memoryManager;
    FIFO fifoAlgorithm;
    LRU lruAlgorithm;
    std::vector<int> accessPattern;
    size_t currentAccessIndex;
    QTimer* autoRunTimer;
    bool isRunning;
    
    // UI Components
    std::vector<QLabel*> frameLabels;
    std::vector<QLabel*> pageTableLabels;
    QLabel* accessesLabel;
    QLabel* faultsLabel;
    QLabel* hitRateLabel;
    QLabel* replacementsLabel;
    QLabel* messageLabel;
    QLabel* progressLabel;
    QTextEdit* patternDisplay;
    QPushButton* stepButton;
    QPushButton* runButton;
    QPushButton* resetButton;
    QComboBox* algorithmCombo;
    
    void setupUI();
    void updateVisualization();
    void performStep();
    void loadAccessPattern();

private slots:
    void onStepClicked();
    void onRunClicked();
    void onResetClicked();
    void onAlgorithmChanged(int index);
    void onAutoRunTimeout();

public:
    MainWindow(QWidget* parent = nullptr);
    ~MainWindow();
};

#endif
EOF

echo "Creating MainWindow.cpp (this is a large file)..."

# I'll create the MainWindow.cpp in the actual directory
# Due to length, showing you the command structure

cat > src/gui/MainWindow.cpp << 'MAINWINDOW_EOF'
#include "MainWindow.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QGridLayout>
#include <QGroupBox>
#include <QFont>
#include <sstream>

MainWindow::MainWindow(QWidget* parent)
    : QMainWindow(parent), currentAccessIndex(0), isRunning(false) {
    memoryManager = new MemoryManager(8, 10, &fifoAlgorithm);
    autoRunTimer = new QTimer(this);
    connect(autoRunTimer, &QTimer::timeout, this, &MainWindow::onAutoRunTimeout);
    
    loadAccessPattern();
    setupUI();
    updateVisualization();
}

MainWindow::~MainWindow() {
    delete memoryManager;
}

void MainWindow::loadAccessPattern() {
    accessPattern = {0, 1, 2, 3, 0, 1, 4, 0, 1, 2, 3, 4, 5, 6, 7, 8, 1, 2, 3, 0};
}

void MainWindow::setupUI() {
    setWindowTitle("Memory Manager Simulator");
    resize(1000, 700);
    
    QWidget* central = new QWidget(this);
    QVBoxLayout* mainLayout = new QVBoxLayout(central);
    
    // Physical Memory Section
    QGroupBox* memoryGroup = new QGroupBox("Physical Memory (8 Frames)");
    QGridLayout* memoryLayout = new QGridLayout();
    
    for (int i = 0; i < 8; i++) {
        QLabel* label = new QLabel("---");
        label->setAlignment(Qt::AlignCenter);
        label->setMinimumSize(80, 80);
        label->setStyleSheet("QLabel { background: #f0f0f0; border: 2px solid #ddd; "
                           "border-radius: 6px; font-size: 18px; font-weight: bold; }");
        frameLabels.push_back(label);
        memoryLayout->addWidget(label, 0, i);
        
        QLabel* frameNum = new QLabel(QString("F%1").arg(i));
        frameNum->setAlignment(Qt::AlignCenter);
        frameNum->setStyleSheet("font-size: 10px; color: #666;");
        memoryLayout->addWidget(frameNum, 1, i);
    }
    memoryGroup->setLayout(memoryLayout);
    mainLayout->addWidget(memoryGroup);
    
    // Page Table Section
    QGroupBox* pageGroup = new QGroupBox("Page Table");
    QGridLayout* pageLayout = new QGridLayout();
    
    for (int i = 0; i < 10; i++) {
        QLabel* label = new QLabel(QString("P%1\n---").arg(i));
        label->setAlignment(Qt::AlignCenter);
        label->setMinimumSize(60, 50);
        label->setStyleSheet("QLabel { background: white; border: 1px solid #ddd; "
                           "border-radius: 4px; padding: 5px; }");
        pageTableLabels.push_back(label);
        pageLayout->addWidget(label, 0, i);
    }
    pageGroup->setLayout(pageLayout);
    mainLayout->addWidget(pageGroup);
    
    // Message Display
    messageLabel = new QLabel("Click Step to begin simulation");
    messageLabel->setStyleSheet("QLabel { background: #fffaf0; border: 2px solid #f6ad55; "
                               "border-radius: 6px; padding: 12px; font-weight: bold; }");
    messageLabel->setWordWrap(true);
    mainLayout->addWidget(messageLabel);
    
    progressLabel = new QLabel("Progress: 0/20");
    progressLabel->setStyleSheet("color: #666; font-size: 12px;");
    mainLayout->addWidget(progressLabel);
    
    // Statistics Section
    QGroupBox* statsGroup = new QGroupBox("Statistics");
    QGridLayout* statsLayout = new QGridLayout();
    
    accessesLabel = new QLabel("0");
    faultsLabel = new QLabel("0");
    hitRateLabel = new QLabel("0%");
    replacementsLabel = new QLabel("0");
    
    QFont statFont;
    statFont.setPointSize(24);
    statFont.setBold(true);
    
    accessesLabel->setFont(statFont);
    faultsLabel->setFont(statFont);
    hitRateLabel->setFont(statFont);
    replacementsLabel->setFont(statFont);
    
    statsLayout->addWidget(new QLabel("Total Accesses"), 0, 0);
    statsLayout->addWidget(accessesLabel, 1, 0);
    statsLayout->addWidget(new QLabel("Page Faults"), 0, 1);
    statsLayout->addWidget(faultsLabel, 1, 1);
    statsLayout->addWidget(new QLabel("Hit Rate"), 0, 2);
    statsLayout->addWidget(hitRateLabel, 1, 2);
    statsLayout->addWidget(new QLabel("Replacements"), 0, 3);
    statsLayout->addWidget(replacementsLabel, 1, 3);
    
    statsGroup->setLayout(statsLayout);
    mainLayout->addWidget(statsGroup);
    
    // Controls Section
    QGroupBox* controlGroup = new QGroupBox("Controls");
    QHBoxLayout* controlLayout = new QHBoxLayout();
    
    algorithmCombo = new QComboBox();
    algorithmCombo->addItem("Algorithm: FIFO");
    algorithmCombo->addItem("Algorithm: LRU");
    connect(algorithmCombo, QOverload<int>::of(&QComboBox::currentIndexChanged),
            this, &MainWindow::onAlgorithmChanged);
    
    stepButton = new QPushButton("Step");
    runButton = new QPushButton("Run");
    resetButton = new QPushButton("Reset");
    
    stepButton->setMinimumHeight(40);
    runButton->setMinimumHeight(40);
    resetButton->setMinimumHeight(40);
    
    connect(stepButton, &QPushButton::clicked, this, &MainWindow::onStepClicked);
    connect(runButton, &QPushButton::clicked, this, &MainWindow::onRunClicked);
    connect(resetButton, &QPushButton::clicked, this, &MainWindow::onResetClicked);
    
    controlLayout->addWidget(algorithmCombo);
    controlLayout->addWidget(stepButton);
    controlLayout->addWidget(runButton);
    controlLayout->addWidget(resetButton);
    
    controlGroup->setLayout(controlLayout);
    mainLayout->addWidget(controlGroup);
    
    // Access Pattern Display
    patternDisplay = new QTextEdit();
    patternDisplay->setReadOnly(true);
    patternDisplay->setMaximumHeight(80);
    
    std::ostringstream pattern;
    pattern << "Access Pattern: ";
    for (size_t i = 0; i < accessPattern.size(); i++) {
        pattern << "P" << accessPattern[i];
        if (i < accessPattern.size() - 1) pattern << ", ";
    }
    patternDisplay->setText(QString::fromStdString(pattern.str()));
    mainLayout->addWidget(patternDisplay);
    
    setCentralWidget(central);
}

void MainWindow::updateVisualization() {
    const auto& memory = memoryManager->getPhysicalMemory();
    const auto& pageTable = memoryManager->getPageTable();
    const auto& stats = memoryManager->getStatistics();
    
    // Update physical memory
    for (size_t i = 0; i < memory.size(); i++) {
        if (memory[i] == -1) {
            frameLabels[i]->setText("---");
            frameLabels[i]->setStyleSheet("QLabel { background: #f0f0f0; border: 2px solid #ddd; "
                                        "border-radius: 6px; font-size: 18px; font-weight: bold; color: #ccc; }");
        } else {
            frameLabels[i]->setText(QString("P%1").arg(memory[i]));
            frameLabels[i]->setStyleSheet("QLabel { background: #48bb78; border: 2px solid #38a169; "
                                        "border-radius: 6px; font-size: 18px; font-weight: bold; color: white; }");
        }
    }
    
    // Update page table
    for (int i = 0; i < pageTable.getTotalPages(); i++) {
        QString text = QString("P%1\n").arg(i);
        if (pageTable.isValid(i)) {
            text += QString("F%1").arg(pageTable.getFrameNumber(i));
            pageTableLabels[i]->setStyleSheet("QLabel { background: #ebf8ff; border: 1px solid #4299e1; "
                                            "border-radius: 4px; padding: 5px; font-weight: bold; }");
        } else {
            text += "---";
            pageTableLabels[i]->setStyleSheet("QLabel { background: white; border: 1px solid #ddd; "
                                            "border-radius: 4px; padding: 5px; }");
        }
        pageTableLabels[i]->setText(text);
    }
    
    // Update statistics
    accessesLabel->setText(QString::number(stats.totalAccesses));
    faultsLabel->setText(QString::number(stats.pageFaults));
    hitRateLabel->setText(QString::number(stats.getHitRate(), 'f', 1) + "%");
    replacementsLabel->setText(QString::number(stats.replacements));
    
    // Update progress
    progressLabel->setText(QString("Progress: %1/%2")
                          .arg(currentAccessIndex)
                          .arg(accessPattern.size()));
}

void MainWindow::performStep() {
    if (currentAccessIndex >= accessPattern.size()) {
        messageLabel->setText("✅ Simulation Complete!");
        messageLabel->setStyleSheet("QLabel { background: #f0fff4; border: 2px solid #48bb78; "
                                   "border-radius: 6px; padding: 12px; font-weight: bold; }");
        isRunning = false;
        autoRunTimer->stop();
        runButton->setText("Run");
        return;
    }
    
    int pageNum = accessPattern[currentAccessIndex];
    std::string result = memoryManager->accessPage(pageNum);
    
    messageLabel->setText(QString::fromStdString(result));
    
    if (result.find("HIT") != std::string::npos) {
        messageLabel->setStyleSheet("QLabel { background: #f0fff4; border: 2px solid #48bb78; "
                                   "border-radius: 6px; padding: 12px; font-weight: bold; }");
    } else {
        messageLabel->setStyleSheet("QLabel { background: #fffaf0; border: 2px solid #f6ad55; "
                                   "border-radius: 6px; padding: 12px; font-weight: bold; }");
    }
    
    currentAccessIndex++;
    updateVisualization();
}

void MainWindow::onStepClicked() {
    if (!isRunning) {
        performStep();
    }
}

void MainWindow::onRunClicked() {
    isRunning = !isRunning;
    
    if (isRunning) {
        runButton->setText("Pause");
        stepButton->setEnabled(false);
        algorithmCombo->setEnabled(false);
        autoRunTimer->start(800);
    } else {
        runButton->setText("Run");
        stepButton->setEnabled(true);
        autoRunTimer->stop();
    }
}

void MainWindow::onResetClicked() {
    isRunning = false;
    autoRunTimer->stop();
    currentAccessIndex = 0;
    memoryManager->reset();
    updateVisualization();
    
    messageLabel->setText("Click Step to begin simulation");
    messageLabel->setStyleSheet("QLabel { background: #fffaf0; border: 2px solid #f6ad55; "
                               "border-radius: 6px; padding: 12px; font-weight: bold; }");
    runButton->setText("Run");
    stepButton->setEnabled(true);
    algorithmCombo->setEnabled(true);
}

void MainWindow::onAlgorithmChanged(int index) {
    if (memoryManager->getStatistics().totalAccesses > 0) {
        return; // Don't change algorithm mid-simulation
    }
    
    delete memoryManager;
    
    if (index == 0) {
        memoryManager = new MemoryManager(8, 10, &fifoAlgorithm);
    } else {
        memoryManager = new MemoryManager(8, 10, &lruAlgorithm);
    }
    
    updateVisualization();
}

void MainWindow::onAutoRunTimeout() {
    performStep();
    
    if (currentAccessIndex >= accessPattern.size()) {
        isRunning = false;
        autoRunTimer->stop();
        runButton->setText("Run");
        stepButton->setEnabled(true);
    }
}
MAINWINDOW_EOF

# main.cpp
cat > src/main.cpp << 'EOF'
#include <QApplication>
#include "MainWindow.h"

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);
    
    MainWindow window;
    window.show();
    
    return app.exec();
}
EOF

# access_pattern.txt
cat > data/access_pattern.txt << 'EOF'
0 1 2 3 0 1 4 0 1 2 3 4 5 6 7 8 1 2 3 0
EOF

# README.md
cat > README.md << 'EOF'
# Memory Manager Simulator

A visual simulation of operating system memory management with page replacement algorithms.

## Features
- FIFO and LRU page replacement algorithms
- Real-time visualization of physical memory
- Page table display
- Statistics tracking (hit rate, page faults, replacements)
- Step-by-step or automatic execution

## Build Instructions

### Ubuntu/Linux
```bash
sudo apt install build-essential cmake qtbase5-dev
mkdir build && cd build
cmake ..
make
./MemoryManager
```

## Usage
1. Select algorithm (FIFO or LRU)
2. Click "Step" to execute one memory access
3. Click "Run" to auto-execute all accesses
4. Click "Reset" to start over
EOF

# .gitignore
cat > .gitignore << 'EOF'
build/
*.o
*.user
CMakeCache.txt
CMakeFiles/
Makefile
cmake_install.cmake
MemoryManager
EOF

echo ""
echo "========================================="
echo "All project files created successfully!"
echo "========================================="
echo ""
echo "Project structure:"
tree -L 3 2>/dev/null || find . -type f -name "*.h" -o -name "*.cpp" -o -name "CMakeLists.txt" | sort

#include "MainWindow.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QGridLayout>
#include <QGroupBox>
#include <QFont>
#include <QLineEdit>
#include <QMessageBox>
#include <QRegExp>
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
    // Default pattern
    accessPattern = {0, 1, 2, 3, 0, 1, 2, 3, 4, 5, 0, 1, 2, 3, 6, 7, 0, 1, 2, 3, 8, 9, 0, 1, 2, 3};
}

void MainWindow::setupUI() {
    setWindowTitle("Memory Manager Simulator");
    resize(1000, 750);
    
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
    
    progressLabel = new QLabel("Progress: 0/26");
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
    
    // Access Pattern Input Section
    QGroupBox* patternGroup = new QGroupBox("Access Pattern (Enter page numbers 0-9, separated by commas or spaces)");
    QVBoxLayout* patternLayout = new QVBoxLayout();
    
    patternInput = new QLineEdit();
    patternInput->setPlaceholderText("Example: 0,1,2,3,0,1,4 or 0 1 2 3 0 1 4");
    patternInput->setMinimumHeight(35);
    
    // Set default pattern in the input box
    std::ostringstream pattern;
    for (size_t i = 0; i < accessPattern.size(); i++) {
        pattern << accessPattern[i];
        if (i < accessPattern.size() - 1) pattern << ", ";
    }
    patternInput->setText(QString::fromStdString(pattern.str()));
    
    QPushButton* loadPatternButton = new QPushButton("Load Pattern");
    loadPatternButton->setMinimumHeight(35);
    loadPatternButton->setStyleSheet("QPushButton { background: #4299e1; color: white; font-weight: bold; }");
    connect(loadPatternButton, &QPushButton::clicked, this, [this]() {
        parseAndLoadPattern();
    });
    
    patternLayout->addWidget(patternInput);
    patternLayout->addWidget(loadPatternButton);
    patternGroup->setLayout(patternLayout);
    mainLayout->addWidget(patternGroup);
    
    setCentralWidget(central);
}

void MainWindow::parseAndLoadPattern() {
    // Don't allow changing pattern during simulation
    if (memoryManager->getStatistics().totalAccesses > 0) {
        QMessageBox::warning(this, "Pattern Locked", 
                           "Please reset the simulation before loading a new pattern.");
        return;
    }
    
    QString input = patternInput->text().trimmed();
    if (input.isEmpty()) {
        QMessageBox::warning(this, "Empty Pattern", "Please enter a valid access pattern.");
        return;
    }
    
    // Parse the input (supports both comma and space separated)
    QString normalized = input;
    normalized.replace(",", " ");  // Replace commas with spaces
    normalized.replace("P", "");   // Remove P prefix if user typed it
    normalized.replace("p", "");   // Remove lowercase p too
    
    QStringList tokens = normalized.split(QRegExp("\\s+"), Qt::SkipEmptyParts);
    
    std::vector<int> newPattern;
    bool validInput = true;
    
    for (const QString& token : tokens) {
        bool ok;
        int pageNum = token.toInt(&ok);
        
        if (!ok || pageNum < 0 || pageNum > 9) {
            QMessageBox::critical(this, "Invalid Input", 
                                QString("Invalid page number: %1\nPage numbers must be between 0 and 9.").arg(token));
            validInput = false;
            break;
        }
        newPattern.push_back(pageNum);
    }
    
    if (validInput && !newPattern.empty()) {
        accessPattern = newPattern;
        currentAccessIndex = 0;
        
        // Update progress label
        progressLabel->setText(QString("Progress: 0/%1").arg(accessPattern.size()));
        
        QMessageBox::information(this, "Pattern Loaded", 
                               QString("Successfully loaded pattern with %1 accesses.").arg(newPattern.size()));
    } else if (newPattern.empty()) {
        QMessageBox::warning(this, "Empty Pattern", "No valid page numbers found.");
    }
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

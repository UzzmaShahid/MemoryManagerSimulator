#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QLabel>
#include <QPushButton>
#include <QComboBox>
#include <QLineEdit>
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
    QLineEdit* patternInput;
    QPushButton* stepButton;
    QPushButton* runButton;
    QPushButton* resetButton;
    QComboBox* algorithmCombo;
    
    void setupUI();
    void updateVisualization();
    void performStep();
    void loadAccessPattern();
    void parseAndLoadPattern();

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

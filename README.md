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

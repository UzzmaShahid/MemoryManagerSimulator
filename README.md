# Memory Manager Simulator

A visual simulation of operating system memory management with page replacement algorithms.

## Features
- FIFO and LRU page replacement algorithms
- Real-time visualization of physical memory
- Page table display
- Statistics tracking (hit rate, page faults, replacements)
- Step-by-step or automatic execution
<img width="440" height="423" alt="image" src="https://github.com/user-attachments/assets/50418cb3-4e5a-4ac6-b3cf-1884d29748a5" />

### FIFO
<img width="439" height="425" alt="image" src="https://github.com/user-attachments/assets/582ca0d1-d555-428a-9afa-f989f5377f7e" />

### LRU
<img width="439" height="423" alt="image" src="https://github.com/user-attachments/assets/691df235-7461-487c-afef-c51fca756129" />


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

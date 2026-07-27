# LASH

High-performance, terminal-styled hash lookup and database management utility. 

Built with a strict focus on operational efficiency and a minimalist visual footprint. The architecture leverages a C++17 backend interfacing with a Log-Structured Merge-tree (LevelDB) for low-latency key-value lookups, driven by a hardware-accelerated Qt6/QML frontend.

## Architecture
* **Core:** C++17
* **Database:** LevelDB
* **UI/UX:** Qt6 / QML 
* **Assets:** Custom typography and iconography are statically embedded into the binary via Qt Resource System (QRC). No external asset paths required.

## Build Dependencies

LASH requires a C++17 compiler and the following libraries:
* CMake (>= 3.16)
* Qt6 (Core, Quick, Gui)
* LevelDB

### Arch Linux
```bash
sudo pacman -S cmake qt6-base qt6-declarative leveldb ninja
```

### Debian/Ubuntu
```bash
sudo apt install build-essential cmake qt6-base-dev qt6-declarative-dev libleveldb-dev
```

## Compilation

Build the executable using CMake out-of-source:
```bash
git clone https://github.com/cyras0x2d/lash.git
cd lash
mkdir build && cd build
cmake -G Ninja ..
ninja
```

## Execution

Run the compiled binary directly:
```bash
./lash
```

## License

Distributed under the GPL-3.0 License.

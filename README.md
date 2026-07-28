# LASH

High-performance, terminal-inspired hash lookup and wordlist database manager.

LASH is a lightweight, hardware-accelerated desktop application designed for security researchers and developers. Powered by an embedded LevelDB key-value engine and a Qt6/QML frontend, it delivers sub-millisecond hash cracking and lookup operations across millions of records.

## Installation

### Latest Release

Download the pre-compiled binary for Linux from the [Releases](https://github.com/cyras0x2d/lash/releases) page.

```bash
# Make binary executable and run
chmod +x lash
./lash
```

---

## Features

- **High-Speed Lookups**: Sub-millisecond hash-to-plaintext queries backed by LevelDB key-value storage.
- **Multi-Digest Indexing**: Parallel generation of MD5, SHA-1, and SHA-256 digests upon wordlist import.
- **Minimalist Cyber UI**: Dark-mode Qt6 interface with embedded assets and custom typography.
- **Dynamic Visual Feedback**: Smooth visual indicators for wordlist indexing, database purging, and match notifications.
- **Wordlist Management**: Fine-grained control over active wordlists with options to keep or clear generated database hashes.
- **Inline Commands & Shortcuts**: Quick command palette execution (`:clear` to wipe database, `Ctrl+L` to clear console output).

---

## Building from Source

### Dependencies

#### Arch Linux
```bash
sudo pacman -S cmake qt6-base qt6-declarative leveldb openssl ninja
```

#### Ubuntu / Debian
```bash
sudo apt update
sudo apt install build-essential cmake qt6-base-dev qt6-declarative-dev libleveldb-dev libssl-dev ninja-build
```

#### Fedora
```bash
sudo dnf install cmake qt6-qtbase-devel qt6-qtdeclarative-devel leveldb-devel openssl-devel ninja-build
```

### Build Steps

```bash
git clone https://github.com/cyras0x2d/lash.git
cd lash
mkdir build && cd build
cmake -G Ninja ..
ninja
./lash
```

---

## Usage

1. **Import Wordlist**: Click **Import Wordlist** to index dictionary files. MD5, SHA-1, and SHA-256 digests are generated in parallel.
2. **Lookup Hash**: Enter an MD5, SHA-1, or SHA-256 hash into the **Enter Hash...** field for instant matching.
3. **Add Word**: Insert individual words into the database using **+ Add**.
4. **Remove Wordlist**: Click **✕** on active wordlists:
   - **KEEP**: Removes wordlist from active view while retaining database hashes.
   - **CLEAR**: Removes wordlist and purges associated hashes from LevelDB.
5. **Command Palette**: Type `:clear` into the input field to wipe the database. Press `Ctrl+L` to clear output.

---

## Author & License

Developed by [Cyras](https://github.com/cyras0x2d) under the [GPL-3.0 License](LICENSE).

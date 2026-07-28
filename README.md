# LASH — LevelDB Hash Lookup Utility

> **High-performance, terminal-inspired hash lookup & wordlist database manager.**

LASH is a lightweight, hardware-accelerated desktop application designed for security researchers, penetration testers, and developers. Built with a C++17 backend and a Qt6/QML interface, LASH leverages an embedded LevelDB key-value store to deliver sub-millisecond hash cracking and lookup operations across millions of records.

---

## 🚀 Key Features

* ⚡ **Lightning-Fast Lookups**: Instant sub-millisecond hash-to-plaintext queries powered by LevelDB key-value storage.
* 🛡️ **Multi-Algorithm Support**: Simultaneously generates and indexes **MD5**, **SHA-1**, and **SHA-256** digests upon wordlist import.
* 🎨 **Sleek Cyber Aesthetic**: Premium dark-mode UI with custom typography, clean responsive layouts, and zero external runtime asset dependencies.
* 🌊 **Real-Time Visual Feedback**:
  * **Fluid Drop Import Indicator**: Dynamic water-drop animation flowing down the central divider during wordlist indexing.
  * **Reverse Drain Purge Stream**: Ascending red energy particle stream with trailing dots when clearing databases or wordlists.
  * **Animated Match Toast**: High-tech spring notification upon cracking a hash match.
* 🗂️ **Wordlist Manager**: Easily add, manage, or remove active wordlists with fine-grained hash control (**KEEP** hashes in DB or **CLEAR** purged entries).
* ⌨️ **Command Palette & Hotkeys**: Inline command execution (e.g., `:clear` to wipe database, `Ctrl+L` to clear output console).

---

## 📦 Easy Installation & Building

### 1. Install Dependencies

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

### 2. Build & Run

Clone the repository and build using Ninja:

```bash
git clone https://github.com/cyras0x2d/lash.git
cd lash
mkdir build && cd build
cmake -G Ninja ..
ninja
```

Launch LASH:

```bash
./lash
```

---

## 💡 Usage Guide

1. **Import Wordlist**: Click **Import Wordlist** to index any plaintext dictionary file. LASH automatically generates MD5, SHA-1, and SHA-256 hashes in parallel.
2. **Lookup Hash**: Enter any valid MD5, SHA-1, or SHA-256 hash into the **Enter Hash...** field to find instant matches.
3. **Add Single Word**: Click **+ Add** to insert individual words directly into the database.
4. **Remove Wordlist**: Click the **✕** icon on any active wordlist item:
   * **KEEP**: Removes the wordlist from active management while keeping compiled hashes in the database.
   * **CLEAR**: Removes the wordlist and purges its generated hashes from LevelDB.
5. **Command Palette**: Type `:clear` into the input field to wipe the entire database. Press `Ctrl+L` or click the trash icon to wipe the console output.

---

## 👤 Author

Developed by [Cyras](https://github.com/cyras0x2d)

## 📄 License

Distributed under the [GPL-3.0 License](LICENSE).

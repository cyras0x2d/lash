#include "HashController.h"
#include <algorithm>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <leveldb/db.h>
#include <leveldb/write_batch.h>
#include <openssl/evp.h>
#include <QFileInfo>
#include <QLocale>
#include <QSettings>
#include <sstream>
#include <string>
#include <thread>
#include <vector>

static std::string hexDigest(const EVP_MD *md, const std::string &input) {
  if (!md) return "";
  EVP_MD_CTX *context = EVP_MD_CTX_new();
  if (!context) return "";

  unsigned char md_value[EVP_MAX_MD_SIZE];
  unsigned int md_len = 0;

  EVP_DigestInit_ex(context, md, nullptr);
  EVP_DigestUpdate(context, input.data(), input.length());
  EVP_DigestFinal_ex(context, md_value, &md_len);
  EVP_MD_CTX_free(context);

  static const char hexDigits[] = "0123456789abcdef";
  std::string hex;
  hex.resize(md_len * 2);
  for (unsigned int i = 0; i < md_len; i++) {
    hex[i * 2]     = hexDigits[(md_value[i] >> 4) & 0x0F];
    hex[i * 2 + 1] = hexDigits[md_value[i] & 0x0F];
  }
  return hex;
}

HashController::HashController(QObject *parent) : QObject(parent) {
  leveldb::Options options;
  options.create_if_missing = true;

  QSettings settings("Cyras", "HashLookup");
  m_activeWordlists = settings.value("activeWordlists").toStringList();

  // Opens or creates the database folder
  leveldb::Status status = leveldb::DB::Open(options, "lash_db", &db);

  if (!status.ok()) {
    emit errorOccurred("Failed to open LevelDB: " +
                       QString::fromStdString(status.ToString()));
  } else {
    std::thread([this]() {
      updateDbStatsCount();
    }).detach();
  }
}

HashController::~HashController() {
  std::lock_guard<std::mutex> lock(dbMutex);
  delete db;
  db = nullptr;
}

QStringList HashController::activeWordlists() const {
  return m_activeWordlists;
}

qint64 HashController::totalHashes() const {
  return m_totalHashes;
}

void HashController::updateDbStatsCount() {
  uint64_t keyCount = 0;
  if (db) {
    leveldb::Iterator *it = db->NewIterator(leveldb::ReadOptions());
    for (it->SeekToFirst(); it->Valid(); it->Next()) {
      keyCount++;
    }
    delete it;
  }
  m_totalHashes = static_cast<qint64>(keyCount);
  emit totalHashesChanged();
}

// The OpenSSL implementation converted to handle Qt's QString
QString HashController::computeHash(const QString &input,
                                    const QString &algorithm) {
  std::string stdInput = input.toStdString();
  std::string stdAlgo = algorithm.toStdString();
  const EVP_MD *md = EVP_get_digestbyname(stdAlgo.c_str());
  if (!md) return "";
  return QString::fromStdString(hexDigest(md, stdInput));
}

void HashController::addWord(const QString &word) {
  std::string stdWord = word.toStdString();
  if (stdWord.empty()) return;

  std::lock_guard<std::mutex> lock(dbMutex);
  if (!db) {
    emit errorOccurred("Database is not initialized.");
    return;
  }

  // Generate all three hashes
  QString md5Hash = computeHash(word, "MD5");
  QString sha1Hash = computeHash(word, "SHA1");
  QString sha256Hash = computeHash(word, "SHA256");

  // Check if the MD5 exists to prevent duplicate entries
  std::string value;
  leveldb::Status s =
      db->Get(leveldb::ReadOptions(), md5Hash.toStdString(), &value);

  if (s.ok()) {
    emit statusUpdate("Word '" + word + "' already exists.");
    return;
  }

  leveldb::WriteOptions writeOpts;
  db->Put(writeOpts, md5Hash.toStdString(), stdWord);
  db->Put(writeOpts, sha1Hash.toStdString(), stdWord);
  db->Put(writeOpts, sha256Hash.toStdString(), stdWord);

  updateDbStatsCount();

  emit statusUpdate("Added word and generated 3 hashes for: " + word);
}

void HashController::lookupHash(const QString &hash) {
  std::lock_guard<std::mutex> lock(dbMutex);
  if (!db || m_totalHashes == 0) {
    emit statusUpdate("ERR_EMPTY");
    return;
  }

  std::string stdHash = hash.toStdString();
  std::string plaintext;

  QString truncHash = hash;
  if (hash.length() > 12) {
    truncHash = hash.left(8) + "..." + hash.right(4);
  }

  // Query LevelDB
  leveldb::Status s = db->Get(leveldb::ReadOptions(), stdHash, &plaintext);

  if (s.ok()) {
    emit matchFound(truncHash + " -> " + QString::fromStdString(plaintext));
  } else {
    emit statusUpdate("[-] MISS  | " + truncHash);
  }
}

void HashController::importWordlist(const QString &filePath) {
  QFileInfo fileInfo(filePath);
  QString fileName = fileInfo.fileName();
  if (fileName.isEmpty()) fileName = filePath;

  {
    std::lock_guard<std::mutex> lock(dbMutex);
    if (!m_activeWordlists.contains(fileName)) {
      m_activeWordlists.append(fileName);
      QSettings settings("Cyras", "HashLookup");
      settings.setValue("activeWordlists", m_activeWordlists);
    }
  }
  emit activeWordlistsChanged();

  std::thread([this, filePath, fileName]() {
    std::string path = filePath.toStdString();
    std::ifstream file(path);

    if (!file.is_open()) {
      emit errorOccurred("Cannot open file: " + fileName);
      return;
    }

    const size_t CHUNK_SIZE = 10000;
    std::vector<std::string> wordChunk;
    wordChunk.reserve(CHUNK_SIZE);

    uint64_t totalWords = 0;

    const EVP_MD *md5 = EVP_md5();
    const EVP_MD *sha1 = EVP_sha1();
    const EVP_MD *sha256 = EVP_sha256();

    auto processChunk = [&](const std::vector<std::string> &words) {
      if (words.empty()) return;

      struct Entry {
        std::string md5;
        std::string sha1;
        std::string sha256;
        std::string word;
      };

      std::vector<Entry> entries(words.size());

      unsigned int numThreads = std::thread::hardware_concurrency();
      if (numThreads == 0) numThreads = 4;

      size_t total = words.size();
      size_t chunkSize = (total + numThreads - 1) / numThreads;

      std::vector<std::thread> workers;
      for (unsigned int t = 0; t < numThreads; ++t) {
        size_t start = t * chunkSize;
        size_t end = std::min(start + chunkSize, total);
        if (start >= total) break;

        workers.emplace_back([&, start, end]() {
          for (size_t i = start; i < end; ++i) {
            entries[i].md5 = hexDigest(md5, words[i]);
            entries[i].sha1 = hexDigest(sha1, words[i]);
            entries[i].sha256 = hexDigest(sha256, words[i]);
            entries[i].word = words[i];
          }
        });
      }

      for (auto &w : workers) {
        if (w.joinable()) w.join();
      }

      leveldb::WriteBatch batch;
      for (const auto &entry : entries) {
        batch.Put(entry.md5, entry.word);
        batch.Put(entry.sha1, entry.word);
        batch.Put(entry.sha256, entry.word);
      }

      {
        std::lock_guard<std::mutex> lock(dbMutex);
        if (db) {
          leveldb::WriteOptions writeOpts;
          db->Write(writeOpts, &batch);
        }
      }
    };

    std::string line;
    while (std::getline(file, line)) {
      while (!line.empty() && (line.back() == '\r' || line.back() == '\n')) {
        line.pop_back();
      }
      if (line.empty()) continue;

      wordChunk.push_back(line);

      if (wordChunk.size() >= CHUNK_SIZE) {
        processChunk(wordChunk);
        totalWords += wordChunk.size();
        wordChunk.clear();
      }
    }

    if (!wordChunk.empty()) {
      processChunk(wordChunk);
      totalWords += wordChunk.size();
      wordChunk.clear();
    }

    file.close();

    updateDbStatsCount();

    QLocale locale(QLocale::English);
    QString wordsStr = locale.toString((qlonglong)totalWords);
    QString hashesStr = locale.toString((qlonglong)(totalWords * 3));

    emit statusUpdate("[+] Imported " + fileName + " (" + wordsStr + " words / " + hashesStr + " hashes)");
  }).detach();
}

void HashController::removeWordlist(const QString &name, bool clearHashes) {
  std::thread([this, name, clearHashes]() {
    {
      std::lock_guard<std::mutex> lock(dbMutex);
      m_activeWordlists.removeAll(name);
      QSettings settings("Cyras", "HashLookup");
      settings.setValue("activeWordlists", m_activeWordlists);

      if (clearHashes && db) {
        leveldb::WriteBatch batch;
        std::ifstream file(name.toStdString());
        if (!file.is_open()) {
          file.open(QFileInfo(name).absoluteFilePath().toStdString());
        }

        if (file.is_open()) {
          const EVP_MD *md5 = EVP_md5();
          const EVP_MD *sha1 = EVP_sha1();
          const EVP_MD *sha256 = EVP_sha256();

          std::string line;
          while (std::getline(file, line)) {
            while (!line.empty() && (line.back() == '\r' || line.back() == '\n')) {
              line.pop_back();
            }
            if (line.empty()) continue;

            batch.Delete(hexDigest(md5, line));
            batch.Delete(hexDigest(sha1, line));
            batch.Delete(hexDigest(sha256, line));
          }
          file.close();
        } else {
          std::vector<std::string> keysToDelete;
          leveldb::Iterator *it = db->NewIterator(leveldb::ReadOptions());
          for (it->SeekToFirst(); it->Valid(); it->Next()) {
            keysToDelete.push_back(it->key().ToString());
          }
          delete it;

          for (const auto &k : keysToDelete) {
            batch.Delete(k);
          }
        }

        leveldb::WriteOptions writeOpts;
        db->Write(writeOpts, &batch);
        db->CompactRange(nullptr, nullptr);
      }
    }

    updateDbStatsCount();
    emit activeWordlistsChanged();

    if (clearHashes) {
      emit statusUpdate("Removed " + name + " and purged hashes from database.");
    } else {
      emit statusUpdate("Removed " + name + " from active view (hashes kept).");
    }
  }).detach();
}

void HashController::getDbStats() {
  std::thread([this]() {
    std::lock_guard<std::mutex> lock(dbMutex);
    if (!db) {
      emit errorOccurred("Database is not initialized.");
      return;
    }

    uint64_t keyCount = 0;
    leveldb::Iterator *it = db->NewIterator(leveldb::ReadOptions());
    for (it->SeekToFirst(); it->Valid(); it->Next()) {
      keyCount++;
    }
    delete it;

    m_totalHashes = static_cast<qint64>(keyCount);
    emit totalHashesChanged();

    emit statusUpdate("Database Stats: ~" + QString::number(keyCount) +
                       " total keys in database.");
  }).detach();
}

void HashController::clearDatabase() {
  std::thread([this]() {
    std::lock_guard<std::mutex> lock(dbMutex);
    if (db) {
      delete db;
      db = nullptr;
    }

    leveldb::Options options;
    leveldb::Status status = leveldb::DestroyDB("lash_db", options);
    if (!status.ok()) {
      emit errorOccurred("Failed to destroy LevelDB: " +
                         QString::fromStdString(status.ToString()));
    }

    options.create_if_missing = true;
    status = leveldb::DB::Open(options, "lash_db", &db);
    if (!status.ok()) {
      emit errorOccurred("Failed to re-open LevelDB after clear: " +
                         QString::fromStdString(status.ToString()));
    } else {
      m_totalHashes = 0;
      m_activeWordlists.clear();
      QSettings settings("Cyras", "HashLookup");
      settings.remove("activeWordlists");
      emit totalHashesChanged();
      emit activeWordlistsChanged();
      emit statusUpdate("Database cleared successfully.");
    }
  }).detach();
}



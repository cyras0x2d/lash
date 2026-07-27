#ifndef HASHCONTROLLER_H
#define HASHCONTROLLER_H

#include <QObject>
#include <QString>
#include <QStringList>
#include <leveldb/db.h>
#include <mutex>

class HashController : public QObject {
  Q_OBJECT
  Q_PROPERTY(QStringList activeWordlists READ activeWordlists NOTIFY activeWordlistsChanged)
  Q_PROPERTY(qint64 totalHashes READ totalHashes NOTIFY totalHashesChanged)

public:
  explicit HashController(QObject *parent = nullptr);
  ~HashController();

  QStringList activeWordlists() const;
  qint64 totalHashes() const;

  // LevelDB state check & CLI helpers
  bool isDbOpen() const;
  bool lookupHashCli(const QString &hash, QString &outPlaintext);
  bool addWordCli(const QString &word);
  bool importWordlistSync(const QString &filePath, uint64_t &outWordsImported);

  // QML GUI Invokable slots
  Q_INVOKABLE void addWord(const QString &word);
  Q_INVOKABLE void lookupHash(const QString &hash);
  Q_INVOKABLE void importWordlist(const QString &filePath);
  Q_INVOKABLE void removeWordlist(const QString &name, bool clearHashes = false);
  Q_INVOKABLE void getDbStats();
  Q_INVOKABLE void clearDatabase();

signals:
  void statusUpdate(const QString &message);
  void matchFound(const QString &plaintext);
  void errorOccurred(const QString &errorMessage);
  void dbLockedError(const QString &errorMessage);
  void activeWordlistsChanged();
  void totalHashesChanged();

private:
  leveldb::DB *db{nullptr};
  std::mutex dbMutex;
  QStringList m_activeWordlists;
  qint64 m_totalHashes{0};

  bool openDatabase();
  void updateDbStatsCount();
  QString computeHash(const QString &input, const QString &algorithm);
};

#endif // HASHCONTROLLER_H

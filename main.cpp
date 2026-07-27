#include "HashController.h"
#include <QCommandLineOption>
#include <QCommandLineParser>
#include <QFile>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QTextStream>
#include <QUrl>
#include <iostream>

int main(int argc, char *argv[]) {
  QGuiApplication app(argc, argv);
  app.setApplicationName("lash");
  app.setApplicationVersion("1.0");

  QCommandLineParser parser;
  parser.setApplicationDescription("LASH - High-Performance Terminal-Styled Hash Lookup Utility");
  parser.addHelpOption();
  parser.addVersionOption();

  QCommandLineOption cliOption(QStringList() << "c" << "cli",
                               "Run in headless CLI mode.");
  parser.addOption(cliOption);

  QCommandLineOption batchOption(QStringList() << "b" << "batch",
                                 "Batch file containing lookups or additions.",
                                 "file");
  parser.addOption(batchOption);

  QCommandLineOption lookupOption(QStringList() << "l" << "lookup",
                                  "Lookup a single hash.",
                                  "hash");
  parser.addOption(lookupOption);

  QCommandLineOption addOption(QStringList() << "a" << "add",
                               "Add a single word to the database.",
                               "word");
  parser.addOption(addOption);

  QCommandLineOption importOption(QStringList() << "i" << "import",
                                  "Import a wordlist file into the database.",
                                  "file");
  parser.addOption(importOption);

  parser.process(app);

  bool isCliMode = parser.isSet(cliOption);

  // If --cli is passed or if CLI flags are set, run headlessly without loading QML GUI
  if (isCliMode || parser.isSet(batchOption) || parser.isSet(lookupOption) ||
      parser.isSet(addOption) || parser.isSet(importOption)) {

    HashController hashController;

    if (!hashController.isDbOpen()) {
      std::cerr << "Error: Failed to open LevelDB database." << std::endl;
      return 1;
    }

    bool hasErrors = false;
    bool operationPerformed = false;

    if (parser.isSet(addOption)) {
      operationPerformed = true;
      QString word = parser.value(addOption);
      if (hashController.addWordCli(word)) {
        std::cout << "[ADDED] " << word.toStdString() << std::endl;
      } else {
        std::cerr << "[ERROR] Failed to add word: " << word.toStdString() << std::endl;
        hasErrors = true;
      }
    }

    if (parser.isSet(importOption)) {
      operationPerformed = true;
      QString filePath = parser.value(importOption);
      uint64_t importedCount = 0;
      if (hashController.importWordlistSync(filePath, importedCount)) {
        std::cout << "[IMPORTED] " << filePath.toStdString() << " (" << importedCount << " words)" << std::endl;
      } else {
        std::cerr << "[ERROR] Failed to import wordlist: " << filePath.toStdString() << std::endl;
        hasErrors = true;
      }
    }

    if (parser.isSet(lookupOption)) {
      operationPerformed = true;
      QString hash = parser.value(lookupOption);
      QString plaintext;
      if (hashController.lookupHashCli(hash, plaintext)) {
        std::cout << "[MATCH] " << hash.toStdString() << " -> " << plaintext.toStdString() << std::endl;
      } else {
        std::cout << "[MISS] " << hash.toStdString() << std::endl;
        hasErrors = true;
      }
    }

    if (parser.isSet(batchOption)) {
      operationPerformed = true;
      QString batchFilePath = parser.value(batchOption);
      QFile file(batchFilePath);
      if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        std::cerr << "[ERROR] Cannot open batch file: " << batchFilePath.toStdString() << std::endl;
        return 1;
      }

      QTextStream in(&file);
      while (!in.atEnd()) {
        QString line = in.readLine().trimmed();
        if (line.isEmpty() || line.startsWith("#")) continue;

        if (line.startsWith("ADD ", Qt::CaseInsensitive)) {
          QString word = line.mid(4).trimmed();
          if (hashController.addWordCli(word)) {
            std::cout << "[ADDED] " << word.toStdString() << std::endl;
          } else {
            std::cerr << "[ERROR] Failed to add word: " << word.toStdString() << std::endl;
            hasErrors = true;
          }
        } else {
          QString hash = line;
          if (line.startsWith("LOOKUP ", Qt::CaseInsensitive)) {
            hash = line.mid(7).trimmed();
          }
          QString plaintext;
          if (hashController.lookupHashCli(hash, plaintext)) {
            std::cout << "[MATCH] " << hash.toStdString() << " -> " << plaintext.toStdString() << std::endl;
          } else {
            std::cout << "[MISS] " << hash.toStdString() << std::endl;
            hasErrors = true;
          }
        }
      }
      file.close();
    }

    if (!operationPerformed) {
      std::cout << "LASH CLI Mode. Use --help for usage details." << std::endl;
    }

    return hasErrors ? 1 : 0;
  }

  // GUI Mode
  HashController hashController;

  QQmlApplicationEngine engine;
  engine.rootContext()->setContextProperty("hashEngine", &hashController);

  const QUrl url(QStringLiteral("qrc:/Main.qml"));
  engine.load(url);

  if (engine.rootObjects().isEmpty()) {
    const QUrl localUrl(QUrl::fromLocalFile("../Main.qml"));
    engine.load(localUrl);
  }

  if (engine.rootObjects().isEmpty())
    return -1;

  return app.exec();
}

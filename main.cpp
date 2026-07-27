#include "HashController.h"
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QUrl>

int main(int argc, char *argv[]) {
  QGuiApplication app(argc, argv);

  // Initialize the LevelDB + OpenSSL backend
  HashController hashController;

  QQmlApplicationEngine engine;

  // Inject the C++ backend into the QML frontend under the name "hashEngine"
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

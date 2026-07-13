#ifdef QT_QML_DEBUG
#include <QtDebug>
#endif

#include <sailfishapp.h>
#include "settings.h"
#include <QtQuick>

#include <QObject>
#include <QDBusConnection>
#include "stumblefish/common/constants.h"

class Fish : public QObject
{
Q_OBJECT
public Q_SLOTS:
    void stumbleReportsChanged() {};
};

#include "harbour-livetrack.moc"

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    QScopedPointer<QQuickView> view(SailfishApp::createView());

    QQmlContext *context = view.data()->rootContext();
    Settings livetracksettings;
    livetracksettings.initialize();
    context->setContextProperty("livetracksettings", &livetracksettings);

    Fish* fish = new Fish();
    context->setContextProperty("StumbleFish", fish);

    QDBusConnection::sessionBus().connect(Stumblefish::ServiceName,
                                          Stumblefish::ObjectPath,
                                          Stumblefish::InterfaceName,
                                          QStringLiteral("reportsChanged"),
                                          fish, SLOT(stumbleReportsChanged()));

    view->setSource(SailfishApp::pathTo("qml/LiveTrack.qml"));
    view->show();
    return app->exec();
}



#include "settings.h"

Settings::Settings() : QSettings(){
    }

void Settings::initialize()
{
    qDebug("Initializing settings");
    if (!this->contains("URL"))
        this->setValue("URL", "https://my.url.local/trackme/");
    if (!this->contains("ID"))
        this->setValue("ID", "jolla");
    if (!this->contains("intervald"))
        this->setValue("intervald", 1000);
    if (!this->contains("intervali"))
        this->setValue("intervali", 0);
    if (!this->contains("autostart"))
        this->setValue("autostart", false);
    if (!this->contains("traccar"))
        this->setValue("traccar", false);

    if (!this->contains("mlscollect"))
        this->setValue("mlscollect", false);
    if (!this->contains("mlssubmit"))
        this->setValue("mlssubmit", false);
    if (!this->contains("mlscustom"))
        this->setValue("mlscustom", false);
    if (!this->contains("MLSURL"))
        this->setValue("MLSURL", "https://api.beacondb.net/v2/geosubmit");
    if (!this->contains("MLSID"))
        this->setValue("MLSID", "geoclue_sailfishos-community");
    if (!this->contains("MLSKEY"))
        this->setValue("MLSKEY", "3Xaimp7E-KeY");
}
void Settings::set(const QString& key, const QVariant &value){
    this->setValue(key, value);
}
QVariant Settings::get(const QString& key){
   QVariant value = this->value(key);
    return value;

}
QString Settings::getString(const QString& key){
   QVariant value = get(key);
   Q_ASSERT(value.canConvert(QVariant::String));
   return value.toString();

}
bool Settings::getBool(const QString& key){
    QVariant value = get(key);
    Q_ASSERT(value.canConvert(QVariant::Bool));
    return value.toBool();

}
int Settings::getInt(const QString& key){
    QVariant value = get(key);
    Q_ASSERT(value.canConvert(QVariant::Int));
    return value.toInt();
}

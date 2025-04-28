import QtQuick 2.6
import Sailfish.Silica 1.0
import "."

Page {
    id: settingspages
    property var textAlignment: undefined
    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height
    Column {
        id: column
        width: settingspages.width
        spacing: Theme.paddingLarge
        PageHeader {
            title: qsTr("Settings")
        }

        SectionHeader { text: qsTr("Location Tracking") }

        TextField {
            id: serverurllabel
            focus: true
            text: livetracksettings.getString("URL")
            label: "Serverurl"
            placeholderText: label
            width: parent.width
            horizontalAlignment: textAlignment
            inputMethodHints: Qt.ImhUrlCharactersOnly
            EnterKey.iconSource: "image://theme/icon-m-enter-next"
            EnterKey.onClicked: idlabel.focus = true
            onTextChanged: {
                //console.log("Got text: " + text);
                // define regexp:
                //  * what we want is inside ()
                //  * everything before the first ?:      [^?]*
                //  * and the / before that:              .*\/[*?]*
                //  * match all the rest after the ? too: .*
                var re = /(.*\/)[^?]*.*/
                // $1 contains the match between the () above
                var newtext = text.replace(re,'$1');
                //console.log("Transformed text: " + newtext);
                livetracksettings.set("URL",newtext)
            }
        }
        TextField {
            id:idlabel
            label: "ID"
            text: livetracksettings.getString("ID")
            placeholderText: label
            width: parent.width
            horizontalAlignment: textAlignment
            EnterKey.iconSource: "image://theme/icon-m-enter-next"
            EnterKey.onClicked: intervaldlabel.focus = true
            onTextChanged:
                livetracksettings.set("ID",text)
        }
        ComboBox {
            anchors.horizontalCenter: parent.horizontalCenter
            label: qsTr("Timer Interval")
            description: "Tap to switch"
            currentIndex: livetracksettings.get("intervali");
            menu: ContextMenu {
                width:parent.width - Theme.paddingLarge * 2
                MenuItem { text: "1s" }
                MenuItem { text: "3s" }
                MenuItem { text: "5s" }
                MenuItem { text: "10s" }
                MenuItem { text: "15s" }
                MenuItem { text: "30s" }
                MenuItem { text: "45s" }
                MenuItem { text: "60s" }
            }
            onValueChanged: {
                var val = parseInt(value.replace("s", "000"))
                positiontimer.intervald=val; livetracksettings.set("intervald",val); livetracksettings.set("intervali",currentIndex)
            }
        }
        TextSwitch {
            id: autostart
            text: "Autostart"
            checked: livetracksettings.getBool("autostart")
            description: "Start tracking automatically when LiveTracker starts"
            onCheckedChanged: {
                livetracksettings.set("autostart",checked)
            }
        }

        TextSwitch {
            id: traccar
            text: "Osmand/ Traccar URL"
            checked: livetracksettings.getBool("traccar")
            description: "Use alternative Osmand URL used by Traccar (?id= instead of /id=)"
            onCheckedChanged: {
                livetracksettings.set("traccar",checked)
            }
        }
        Button {
            id: debug
            text: "Debug"
            onClicked: positiontimer.debug = true;
            enabled: !positiontimer.debug
            anchors.horizontalCenter: parent.horizontalCenter

        }

        Separator { color: Theme.highlightColor }

        SectionHeader { text: qsTr("Cell info collection") }
        TextSwitch {
            id: collect
            text: qsTr("Collect Data")
            checked: livetracksettings.getBool("mlscollect")
            description: qsTr("Collect cell info data.")
            onCheckedChanged: {
                livetracksettings.set("mlscollect",checked)
            }
        }
        TextSwitch {
            id: submit
            text: qsTr("Submit to Server")
            checked: livetracksettings.getBool("mlssubmit")
            description: qsTr("Submit collected cell info data to %1").arg("BeaconDB")
                + "\n" qsTr("If this is off, data will be saved to %1").arg(cellCollectSettings.storage)
            onCheckedChanged: {
                livetracksettings.set("mlssubmit",checked)
            }
        }
        TextSwitch {
            id: mlscustom
            enabled: submit.checked
            text: qsTr("Use custom Server")
            checked: livetracksettings.getBool("mlscustom")
            onCheckedChanged: {
                if (checked) mlsurllabel.focus = true
                livetracksettings.set("mlscustom", checked)
            }
        }
        TextField {
            id: mlsurllabel
            enabled: mlscustom.checked
            text: livetracksettings.getString("MLSURL")
            label: "Serverurl"
            placeholderText: label
            width: parent.width
            horizontalAlignment: textAlignment
            inputMethodHints: Qt.ImhUrlCharactersOnly
            onTextChanged: {
                livetracksettings.set("MLSURL", text)
            }
        }
        TextField {
            id: mlsidlabel
            enabled: mlscustom.checked
            label: "User Id/Nickname"
            text: livetracksettings.getString("MLSID")
            placeholderText: label
            width: parent.width
            horizontalAlignment: textAlignment
            inputMethodHints: Qt.ImhNoAutoUppercase
            onTextChanged: livetracksettings.set("MLSID",text)
        }
        TextField {
            id: mlskeylabel
            enabled: mlscustom.checked
            label: "API/Submission key"
            text: livetracksettings.getString("MLSKEY")
            placeholderText: label
            width: parent.width
            horizontalAlignment: textAlignment
            inputMethodHints: Qt.ImhNoAutoUppercase
            onTextChanged: livetracksettings.set("MLSKEY",text)
        }
    }
    }
}

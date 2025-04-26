import QtQuick 2.6
import org.nemomobile.ofono 1.0

Item {
    id: root

    property bool active: false
    property alias valid: cellInfo.valid
    readonly property int invalidValue: OfonoExtCell.InvalidValue
    property alias count: cellInfoFactory.count
    property int seen: seenCells.length
    property var seenCells: []

    function getCells() {
        var ret = []
        for (var i=0; i<cellInfoFactory.count; i++) {
          var o = cellInfoFactory.objectAt(i)
          //console.debug("cell", i, JSON.stringify(o))
          if (!o.usable) continue
          var r = {}
          // add all valid numbers
          Object.keys(o).forEach(function(k) {
            if (typeof o[k]  == "number") {
              if (o[k] != OfonoExtCell.InvalidValue) { r[k] = o[k] }
            } else if ((k != "objectName") && (k != "valid")) {
              r[k] = o[k]
            }
          })
          ret.push(r)
          console.debug("valid:", JSON.stringify(r))
        }
        return ret
    }
    OfonoExtCellInfo {
        id: cellInfo
        modemPath: root.active ? "/ril_0" : ""
        /*
        onValidChanged: console.debug("cellInfo valid:", valid)
        onCellsRemoved: {
          console.debug("cells removed", cells)
        }
        onCellsAdded: {
          console.debug("cells added", cells)
        }
        */
    }
    Instantiator { id: cellInfoFactory
        model: cellInfo.cells
        delegate: OfonoExtCell {
            property bool usable: (
                   (ci != OfonoExtCell.InvalidValue)
                //&& (mcc != OfonoExtCell.InvalidValue)
                //&& (mnc != OfonoExtCell.InvalidValue)
                && ((type >= 1) && (type <= 3))
                )
             onUsableChanged: {
                 var seen = root.seenCells
                 if (usable && seen.indexOf(ci)>=0) {
                   seen.push(ci)
                   root.seenCells = seen
                 }
             }
             /*
             onPropertyChanged: {
               //if (value != OfonoExtCell.InvalidValue) console.debug("v:", ""+(index+1)+"/"+cellInfoFactory.count, name, value)
               //if (name == "registered" && value) console.debug("registered!")
            }
            */
        }
        onObjectAdded: object.path = model[index]
    }
}

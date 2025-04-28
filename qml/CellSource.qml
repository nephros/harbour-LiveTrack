import QtQuick 2.6
import org.nemomobile.ofono 1.0

Item {
    id: root

    property bool active: false
    property alias valid: cellInfo.valid
    readonly property int invalidValue: OfonoExtCell.InvalidValue
    property alias count: cellInfoFactory.count
    property int strength
    property string tech

    function getCells() {
        var ret = []
        for (var i=0; i<cellInfoFactory.count; i++) {
          var o = cellInfoFactory.objectAt(i)
          //console.debug("cell", i, JSON.stringify(o))
          if (!o.usable) continue
          var r = {}
          if (o.type == 1) r["cellid"] = o.cid
          if (o.type == 3) r["cellid"] = o.ci
          // add all valid numbers
          Object.keys(o).forEach(function(k) {
            if (typeof o[k]  == "number") {
              if (o[k] != OfonoExtCell.InvalidValue) { r[k] = o[k] }
            } else if ((k != "objectName") && (k != "valid") ) {
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
        */
        onCellsAdded: function(cells) {
          console.debug(cells.length, "cells removed, now", cellInfo.cells.length)
        }
        onCellsRemoved: function(cells) {
          console.debug(cells.length, "cells removed, now", cellInfo.cells.length)
        }
    }
    Instantiator { id: cellInfoFactory
        active: root.active
        model: cellInfo.cells
        onObjectAdded: object.path = model[index]
        delegate: OfonoExtCell {
            property int timestamp: OfonoExtCell.InvalidValue
            property bool usable: (
                   ((ci != OfonoExtCell.InvalidValue) || (cid != OfonoExtCell.InvalidValue))
                && ((type == OfonoExtCell.GSM) || (type == OfonoExtCell.WCDMA) || (type == OfonoExtCell.LTE))
                )
             //onPropertyChanged: {}
             onUsableChanged: {
                 timestamp = Date.now()
                 if (registered) {
                     root.strength = signalStrength
                     if (type == OfonoExtCell.LTE) root.tech = "LTE"
                     if (type == OfonoExtCell.GSM) root.tech = "GSM"
                 }

                 var info = this
                 console.debug("cell #", index, ":", JSON.stringify(
                    info,
                    function(k,v) {
                      if (v==OfonoExtCell.InvalidValue) { return undefined }
                      return v
                    }
                 ))
             }
             /*
             onPropertyChanged: {
               //if (value != OfonoExtCell.InvalidValue) console.debug("v:", ""+(index+1)+"/"+cellInfoFactory.count, name, value)
               //if (name == "registered" && value) console.debug("registered!")
            }
            */
        }
    }
}

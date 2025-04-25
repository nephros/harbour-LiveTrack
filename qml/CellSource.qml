import QtQuick 2.6
import org.nemomobile.ofono 1.0

Item {
    id: root

    property alias active: cellInfo.valid

    function getCells() {
        var ret = []
        for (var i=0; i<cellInfoFactory.count; i++) {
          var o = cellInfoFactory.objectAt(i)
          if (o.valid
            && o.cid != OfonoExtCell.InvalidValue
            && o.mcc != OfonoExtCell.InvalidValue
            && o.mnc != OfonoExtCell.InvalidValue
            ) {
              ret.push(o)
          }
        }
        return ret
    }
    OfonoExtCellInfo {
        id: cellInfo
        modemPath: "/ril_0"
        //onValidChanged: console.debug("cellInfo valid:", valid)

        onCellsRemoved: {
          //console.debug("cells removed", cells)
        }
        onCellsAdded: {
          //console.debug("cells added", cells)
          //cellInfoFactory.model = cells
        }
    }
    Instantiator { id: cellInfoFactory
        model: cellInfo.cells
        delegate: OfonoExtCell {
            //onValidChanged: {
            //    if (valid) { 
            //      var info = this; console.debug(JSON.stringify(info))
            //    }
            //}
            //onPropertyChanged: console.info(name,":",value)
        }
        onObjectAdded: object.path = model[index]
    }
}

/*
  Copyright (C) 2013 Jolla Ltd.
  Contact: Thomas Perl <thomas.perl@jollamobile.com>
  All rights reserved.

  You may use this file under the terms of BSD license as follows:

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Jolla Ltd nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR
  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import QtQuick 2.6
import Sailfish.Silica 1.0
import QtPositioning 5.4
import Nemo.Mce 1.0      // power saving mode
import "."

ApplicationWindow
{
    initialPage: Component { FirstPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations
    property alias powersaving: powerSaveMode.active
    McePowerSaveMode { id: powerSaveMode }
    PositionSource { id: gps ; active: !powersaving }
    CellSource { id: cells ; active: cellCollectSettings.enabled && !powersaving }
    PositionTimer {id: positiontimer}
    Timer {id: celltimer
        interval: 1000 * 60 * 5
        repeat: true
        onTriggered: processCells()
        running: cellCollectSettings.enabled && (cells.count > 0) && !powersaving
    }
    Page {id:settingspages;}
    QtObject { id:positiondata
        property var positionvar: [];
    }
    QtObject { id: celldata
        // corresponds to the items property of an ichnaea request payload object
        property var items: []
        property int count: items.length
        readonly property int maxCount: 1000
        onCountChanged: if (count > maxCount) { var old = items; old.shift(); items = old }
        function cellCount() { return items.reduce(function(acc, val, idx){ return acc += val["cellTowers"].length}, 0) }
    }
    QtObject { id: cellCollectSettings
        property bool enabled: livetracksettings.getBool("mlscollect")
        property bool submit: livetracksettings.getBool("mlssubmit")
        readonly property string storage: StandardPaths.documents + "/LiveTrack_celldata_" + today.toISOString().substr(0,10) + ".json"
        readonly property int gpsPrecision: 4
        readonly property int gpsMinPrecision: 250
        property bool custom: livetracksettings.getBool("mlscustom")
        property string nick: custom
            ? livetracksettings.getString("MLSID")
            : 'geoclue_sailfishos-community-testing'
            //: 'geoclue_sailfishos-community'
        property string url: custom
            ? livetracksettings.getString("MLSURL")+"?key=" + livetracksettings.getString("MLSKEY")
            : 'https://api.beacondb.net/v2/geosubmit?key=' + nick
        property string useragent: nick + " (Sailfish OS; " + Qt.application.name + " " + Qt.application.version + ")"
    }
    property int sendgood:0;
    property int cellsendgood:0;
    property int cellsignored:0;
    readonly property string userAgent: Qt.application.name

    readonly property date today: new Date()

//-----------------------Function-----------------------------//
    property bool state: false;


    /* Cell collection logic:

       - cellSource has some cell info
       - celltimer calls processCells which:
         - transforms the cell info into ichnaea request data
         - stores the result via storeCells
       - storeCells:
         - appends its input to the "volatile cache" (celldata.items)
         - if beacondb submission is enabled, calls publishCells
         - else, appends it to the permanent storage (file) via saveCellData
       - publishCells:
           - submits stuff saved in celldata.items
           - calls its success callback on success
    */
    // get cell data from CellSource, and create a valid ichnaea object
    function processCells() {
        var pos
        const acc = cellCollectSettings.gpsPrecision
        const ts = Date.now()
        if(gps.ready && gps.valid &&  (gps.position.horizontalAccuracy < cellCollectSettings.gpsMinPrecision) ){
          pos = { "source": "gps", //.or "fused"
            "latitude":  parseFloat(gps.position.coordinate.latitude.toFixed(acc)),
            "longitude": parseFloat(gps.position.coordinate.longitude.toFixed(acc)),
            "accuracy":  gps.position.horizontalAccuracy, //.toFixed(acc)
            "age": ts - gps.position.timestamp
             }
             if (gps.position.speedValid)
                 pos["speed"] = parseFloat(gps.position.speed.toFixed(acc))
             if (gps.position.directionValid)
                 pos["heading"] = parseFloat(gps.position.direction.toFixed(acc))
             if (gps.position.altitudeValid)
                 pos["altitude"] = parseFloat(gps.position.coordinate.altitude.toFixed(acc))
             if (gps.position.verticalAccuracyValid)
                 pos["altitudeAccuracy"] = parseFloat(gps.position.verticalAccuracy.toFixed(acc))
        } else {
            cellsignored+=1
            return
        }

        //console.debug(JSON.stringify(cells.getCells()))
        var cta = cells.getCells().map(function(cell, idx, arr) {
            const types = [ "Unknown", "gsm", "wcdma", "lte", "nr" ]
            var ret = {
                "cellId": cell.cellid,
                "radioType": types[cell.type],
                "serving": cell.registered,
                "asu": cell.signalStrength,
                "signalStrength": cell.signalLevelDbm
            }
            if ((cell.mcc) && (cell.mnc)) {
                ret["mobileCountryCode"] = cell.mcc
                ret["mobileNetworkCode"] = cell.mnc
            }
            if (!!cell.timestamp && (cell.timestamp != cells.invalidValue))
                ret["age"] = ts - cell.timestamp
            if (!!cell.tac && (cell.tac != cells.invalidValue))
                ret["timingAdvance"] = cell.tac
            if (!!cell.pci && (cell.pci != cells.invalidValue) && (types[cell.type] == "lte"))
                ret["primaryScramblingCode"] = cell.pci
            if (!!cell.lac && cell.lac != cells.invalidValue)
                ret["locationAreaCode"] = cell.lac
            // sanity check
            if (!!cell.cellid && (cell.cellid == cells.invalidValue)) {
                console.warn("BUG: Info has invalid cell ID!")
                return undefined
            }
            return ret
        })
        if (!cta.length) {
          console.warn("No valid cells!")
          cellsignored+=1
          return
        }
        console.debug("got usable cells:", cta.length +"/"+ cells.count)

        var payload = { "items": [
                { "timestamp": ts, "cellTowers": [], "position": {} }
            ]}
        payload.items[0].cellTowers = cta
        payload.items[0].position = pos
        console.debug("Collection payload:", JSON.stringify(payload))
        storeCells(payload)
    }
    // store cell data payload in "volatile cache":
    function storeCells(payload) {
        const items = celldata.items.concat(payload.items)
        celldata.items = items
        function success() { celldata.items = [] }
        if (celldata.items.length > 0) {
            if (cellCollectSettings.submit) {
                publishCells( { "items": celldata.items }, success())
            } else {
                saveCellData(success())
            }
        }
    }
    // load local file, execute callback on it
    function loadCellData(callback) {
        const url = Qt.resolvedUrl(cellCollectSettings.storage)
        var req = new XMLHttpRequest()
        req.onreadystatechange = function() {
            if (req.readyState === XMLHttpRequest.DONE) {
                try {
                    const data = JSON.parse(responseText)
                    callback(data)
                } catch (e) {
                    callback(null)
                }
            }
        }
        req.open("GET", url);
        req.send()
    }
    // load local file, append our cached items, and save again
    function saveCellData(onsuccess) {
        const url = Qt.resolvedUrl(cellCollectSettings.storage)
        loadCellData(function(response) {
            var data = { "items": [] }
            if (response != null) {
                console.debug("Found and parsed previous data file")
                data.items = response.items.concat(celldata.items)
            } else {
                console.debug("Creating new data file")
                data.items = celldata.items
            }
            var req = new XMLHttpRequest()
            req.onreadystatechange = function() {
                if (req.readyState === XMLHttpRequest.DONE) {
                    onsuccess
                    console.debug("Saved cell data")
                }
            }
            req.open("PUT", url);
            req.send(JSON.stringify(data, null, 2))
        })
    }
    function publishCells(payload, onsuccess) {
        var http = new XMLHttpRequest()
        const url  = cellCollectSettings.url
        const nick = cellCollectSettings.nick
        const ua = cellCollectSettings.useragent
        http.open("POST", url);
        http.setRequestHeader("User-Agent", ua)
        http.setRequestHeader("X-Nickname", nick)
        http.setRequestHeader("Content-Type", "application/json")
        http.onreadystatechange = function() {
            if (http.readyState === XMLHttpRequest.DONE) {
                if (http.status === 200) {
                    cellsendgood += payload.items.reduce(function(acc, val, idx){ return acc += val["cellTowers"].length}, 0)
                    console.info("Submitted.")
                    console.debug(JSON.stringify(payload))
                    if (typeof onsuccess === 'function') onsuccess()
                } else {
                    console.warn("Submission failed:", http.statusText)
                    console.debug(JSON.stringify(payload))
                }
            }
        }
        http.send(JSON.stringify(payload));
    }
    function sendData(index) {
        var http = new XMLHttpRequest()
        var url
        if(livetracksettings.getBool("traccar")) {
            url = livetracksettings.getString("URL")+"?id="+livetracksettings.getString("ID")+"&lat=" + positiondata.positionvar[index].positn.latitude +"&lon="+ positiondata.positionvar[index].positn.longitude+"&timestamp="+ positiondata.positionvar[index].timestamp+"&alt="+ positiondata.positionvar[index].alt+"&speed="+ positiondata.positionvar[index].speed+"&acc="+ positiondata.positionvar[index].horizontalAccuracy;
        }
        else {
            url = livetracksettings.getString("URL")+livetracksettings.getString("ID")+"?lat=" + positiondata.positionvar[index].positn.latitude +"&lon="+ positiondata.positionvar[index].positn.longitude+"&timestamp="+ positiondata.positionvar[index].timestamp+"&alt="+ positiondata.positionvar[index].alt+"&speed="+ positiondata.positionvar[index].speed+"&acc="+ positiondata.positionvar[index].horizontalAccuracy+"&useragent=" + userAgent;
        }
        http.open("Get", url, true); //true=asynchronus,false=synchronus
        http.onreadystatechange = function() {
            if (http.readyState === XMLHttpRequest.DONE) {
                if (http.status === 200) {
                    positiondata.positionvar.splice(index, 1);
                    sendgood++;
                } else {
                    positiondata.positionvar[index].dirty=false;
                }
            }
        };
        http.send();
        return true;
    }
//------------------------------------------------------------//

}


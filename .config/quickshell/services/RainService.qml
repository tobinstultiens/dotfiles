pragma Singleton
import Quickshell.Io
import QtQuick

// Fetches 2-hour precipitation forecast from Open-Meteo (minutely_15).
// Returns 8 readings at 15-minute intervals. Refreshes every 10 minutes.
QtObject {
    id: root

    // [{minutes: int, mmh: real}] — 8 entries, 15-min intervals
    property var  readings: []
    property bool hasData:  readings.length > 0
    property bool hasRain:  {
        for (var i = 0; i < readings.length; i++)
            if (readings[i].mmh > 0) return true
        return false
    }
    property real maxMmh: {
        var m = 0
        for (var i = 0; i < readings.length; i++)
            if (readings[i].mmh > m) m = readings[i].mmh
        return Math.max(0.5, m)
    }

    property string _buf: ""

    property var _impl: Item {

        Timer {
            interval: 600000   // every 10 minutes
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: fetchProc.running = true
        }

        Process {
            id: fetchProc
            command: [
                "bash", "-c",
                "curl -sf --max-time 15 " +
                "'https://api.open-meteo.com/v1/forecast" +
                "?latitude=51.4&longitude=5.5" +
                "&minutely_15=precipitation" +
                "&timezone=Europe%2FAmsterdam" +
                "&forecast_minutely_15=8' 2>/dev/null"
            ]
            stdout: SplitParser { onRead: line => { root._buf += line } }
            onExited: (code) => {
                if (code !== 0 || root._buf.trim() === "") { root._buf = ""; return }
                try {
                    var d    = JSON.parse(root._buf)
                    var vals = d.minutely_15.precipitation
                    var result = []
                    for (var i = 0; i < vals.length; i++)
                        result.push({ minutes: i * 15, mmh: vals[i] || 0 })
                    root.readings = result
                } catch(e) {}
                root._buf = ""
            }
        }
    }
}

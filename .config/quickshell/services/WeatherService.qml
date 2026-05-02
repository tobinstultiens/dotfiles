pragma Singleton
import Quickshell.Io
import QtQuick

// Fetches weather from Open-Meteo (free, no API key).
// Location: Eindhoven area (from wlsunset config lat=51.2 lon=5.7)
QtObject {
    id: root

    // Current conditions
    property real   currentTemp:     0
    property int    currentCode:     0
    property real   currentWind:     0
    property int    currentHumidity: 0
    property string currentIcon:     "󰖙"
    property string currentDesc:     "Clear"

    // 5-day forecast [{code, high, low, icon, desc}, ...]
    property var forecast: []

    property bool loading: false
    property bool hasData: false

    property string _buf: ""

    signal fetchNeeded()

    // WMO weather code → {icon, description}
    function _decode(code) {
        if (code === 0)              return { icon: "󰖙", desc: "Clear" }
        if (code <= 2)               return { icon: "󰖕", desc: "Partly cloudy" }
        if (code === 3)              return { icon: "󰖐", desc: "Overcast" }
        if (code <= 48)              return { icon: "󰖑", desc: "Foggy" }
        if (code <= 55)              return { icon: "󰖗", desc: "Drizzle" }
        if (code <= 67)              return { icon: "󰖗", desc: "Rain" }
        if (code <= 77)              return { icon: "󰖘", desc: "Snow" }
        if (code <= 82)              return { icon: "󰖗", desc: "Showers" }
        if (code <= 84)              return { icon: "󰖘", desc: "Snow showers" }
        if (code <= 99)              return { icon: "󰖔", desc: "Thunderstorm" }
        return { icon: "󰖐", desc: "Unknown" }
    }

    property var _impl: Item {

        // Fetch on startup, then every 30 minutes
        Timer {
            interval: 1800000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: root.fetchNeeded()
        }

        Connections {
            target: root
            function onFetchNeeded() {
                root.loading = true
                fetchProc.running = true
            }
        }

        Process {
            id: fetchProc
            command: [
                "bash", "-c",
                "curl -sf --max-time 15 " +
                "'https://api.open-meteo.com/v1/forecast" +
                "?latitude=51.4&longitude=5.5" +
                "&current=temperature_2m,weathercode,windspeed_10m,relative_humidity_2m" +
                "&daily=weathercode,temperature_2m_max,temperature_2m_min" +
                "&timezone=Europe%2FAmsterdam&forecast_days=5' 2>/dev/null"
            ]
            stdout: SplitParser { onRead: line => { root._buf += line } }
            onExited: (code, status) => {
                root.loading = false
                if (code !== 0 || root._buf === "") {
                    root._buf = ""
                    return
                }
                try {
                    var d = JSON.parse(root._buf)
                    var cur = d.current

                    root.currentTemp     = Math.round(cur.temperature_2m)
                    root.currentCode     = cur.weathercode
                    root.currentWind     = Math.round(cur.windspeed_10m)
                    root.currentHumidity = Math.round(cur.relative_humidity_2m)

                    var w = root._decode(cur.weathercode)
                    root.currentIcon = w.icon
                    root.currentDesc = w.desc

                    var days = []
                    var codes = d.daily.weathercode
                    var highs = d.daily.temperature_2m_max
                    var lows  = d.daily.temperature_2m_min
                    for (var i = 0; i < Math.min(5, codes.length); i++) {
                        var dw = root._decode(codes[i])
                        days.push({
                            code: codes[i],
                            high: Math.round(highs[i]),
                            low:  Math.round(lows[i]),
                            icon: dw.icon,
                            desc: dw.desc
                        })
                    }
                    root.forecast = days
                    root.hasData  = true
                } catch(e) {
                    console.warn("WeatherService: parse error:", e)
                }
                root._buf = ""
            }
        }
    }

    Component.onCompleted: fetchNeeded()
}

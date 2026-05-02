import Quickshell.Io
import QtQuick

// Real audio-reactive visualizer using cava's ASCII stdout output.
// Writes a config via python3 on startup, then spawns cava when playing=true.
Item {
    id: root

    property int   bars:     12
    property color barColor: "white"
    property bool  playing:  false
    property real  barWidth: 3
    property real  spacing:  2

    implicitWidth:  bars * (barWidth + spacing) - spacing
    implicitHeight: 16

    // Normalised bar values 0.0–1.0; reassigned each cava frame
    property var _values: _emptyValues()
    property bool _confReady: false

    readonly property string _confPath: "/tmp/cava_qs_" + root.bars + ".conf"

    function _emptyValues() {
        var arr = []
        for (var i = 0; i < bars; i++) arr.push(0)
        return arr
    }

    // Write cava config once on startup via python3 (avoids heredoc quoting issues)
    Process {
        id: writeConf
        running: false
        command: [
            "python3", "-c",
            "import pathlib; pathlib.Path('" + root._confPath + "').write_text(" +
            "'[input]\\nmethod = pipewire\\n" +
            "[output]\\nmethod = raw\\nraw_target = /dev/stdout\\n" +
            "data_format = ascii\\nascii_max_range = 100\\nbar_delimiter = 59\\n" +
            "bars = " + root.bars + "\\n" +
            "[general]\\nframerate = 60\\n" +
            "[smoothing]\\nintegral = 70\\nmonstercat = 1\\nwaves = 0\\n')"
        ]
        onExited: root._confReady = true
    }

    Component.onCompleted: writeConf.running = true

    // bar_delimiter=59 is ASCII for ';'; each line is one frame of bar values
    Process {
        id: cavaProc
        running: root._confReady && root.playing
        command: ["cava", "-p", root._confPath]

        stdout: SplitParser {
            onRead: line => {
                var raw = line.trim()
                if (raw === "") return
                var parts = raw.split(";")
                var vals = []
                for (var i = 0; i < root.bars; i++) {
                    var n = i < parts.length ? parseInt(parts[i]) : 0
                    vals.push(isNaN(n) ? 0 : n / 100.0)
                }
                root._values = vals
            }
        }

        onRunningChanged: {
            if (!running) root._values = root._emptyValues()
        }
    }

    Row {
        anchors.fill: parent
        spacing: root.spacing

        Repeater {
            model: root.bars

            Rectangle {
                width:  root.barWidth
                height: Math.max(2, root.implicitHeight * (root._values[index] || 0))
                anchors.bottom: parent.bottom
                radius: width / 2
                color:  root.barColor

                Behavior on height {
                    NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
                }
            }
        }
    }
}

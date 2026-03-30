import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import "../.." 1.0

Item {
    id: root
    implicitHeight: visible ? col.implicitHeight : 0
    visible: maxBrightness > 0

    property bool active:            false
    property int  currentBrightness: 0
    property int  maxBrightness:     0
    property real percent:           maxBrightness > 0 ? currentBrightness / maxBrightness : 0
    property bool dragging:          false

    onActiveChanged: if (active && maxBrightness === 0) readProc.running = true

    Timer {
        interval: 5000
        running: root.active
        repeat: true
        onTriggered: if (!root.dragging) readProc.running = true
    }

    // brightnessctl -m → device,class,current,percent%,max
    Process {
        id: readProc
        command: [
            "bash", "-c",
            "brightnessctl -m 2>/dev/null | grep -i 'backlight' | head -1"
        ]
        stdout: SplitParser {
            onRead: line => {
                const p = line.split(",")
                if (p.length >= 5) {
                    root.currentBrightness = parseInt(p[2]) || 0
                    root.maxBrightness     = parseInt(p[4]) || 0
                }
            }
        }
    }

    Process {
        id: setProc
        property string pct: "50%"
        command: ["bash", "-c", "brightnessctl set " + setProc.pct]
    }

    function setBrightness(val) {
        setProc.pct = Math.round(val * 100) + "%"
        setProc.running = true
        root.currentBrightness = Math.round(val * root.maxBrightness)
    }

    Column {
        id: col
        width: parent.width
        spacing: 8

        Text {
            text: "BRIGHTNESS"
            font.pixelSize: 10
            font.weight: Font.Medium
            color: Colors.overlay1
            leftPadding: 2
        }

        Rectangle {
            width: parent.width
            height: 54
            color: Colors.surface0
            radius: 8

            Column {
                anchors { left: parent.left; right: parent.right; leftMargin: 12; rightMargin: 12; verticalCenter: parent.verticalCenter }
                spacing: 8

                Row {
                    spacing: 8
                    Text {
                        text: "󰃠"
                        font.pixelSize: 16
                        color: Colors.yellow
                        font.family: "JetBrainsMono Nerd Font"
                    }
                    Text {
                        text: Math.round(root.percent * 100) + "%"
                        font.pixelSize: 12
                        color: Colors.text
                    }
                }

                Slider {
                    id: slider
                    width: parent.width
                    from: 0.05; to: 1.0
                    value: root.percent
                    onPressedChanged: root.dragging = pressed
                    onMoved: root.setBrightness(value)

                    background: Rectangle {
                        x: slider.leftPadding
                        y: slider.topPadding + slider.availableHeight / 2 - height / 2
                        width: slider.availableWidth; height: 5; radius: 3
                        color: Colors.surface1
                        Rectangle {
                            width: slider.visualPosition * parent.width
                            height: parent.height; radius: parent.radius
                            color: Colors.yellow
                        }
                    }

                    handle: Rectangle {
                        x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                        y: slider.topPadding + slider.availableHeight / 2 - height / 2
                        width: 14; height: 14; radius: 7
                        color: Colors.yellow
                    }
                }
            }
        }
    }
}

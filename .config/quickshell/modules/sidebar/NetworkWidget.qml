import Quickshell
import Quickshell.Io
import QtQuick
import "../.." 1.0

Item {
    id: root
    implicitHeight: col.implicitHeight

    property bool   active:    false
    property string connType:  "none"   // "wifi" | "ethernet" | "none"
    property string connName:  ""
    property string ssid:      ""
    property int    signal:    0
    property string ifaceName: ""
    property string downSpeed: "0 B/s"
    property string upSpeed:   "0 B/s"

    // Previous /proc/net/dev counters for delta calculation
    property real _prevRx: 0
    property real _prevTx: 0

    function formatSpeed(bytesPerSec) {
        if (bytesPerSec >= 1048576)
            return (bytesPerSec / 1048576).toFixed(1) + " MB/s"
        if (bytesPerSec >= 1024)
            return Math.round(bytesPerSec / 1024) + " KB/s"
        return Math.round(bytesPerSec) + " B/s"
    }

    // Connection type — poll every 10s when active
    Timer {
        interval: 10000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: netProc.running = true
    }

    Process {
        id: netProc
        command: [
            "bash", "-c",
            "nmcli -t -f device,type,state,connection dev status 2>/dev/null | " +
            "grep -v '^lo\\|loopback\\|p2p' | grep ':connected:' | head -1"
        ]
        stdout: SplitParser {
            onRead: line => {
                const p = line.trim().split(":")
                root.ifaceName = p[0] || ""
                root.connType  = p[1] || "none"
                root.connName  = p[3] || ""
                if (root.connType === "wifi") wifiProc.running = true
            }
        }
    }

    Process {
        id: wifiProc
        command: [
            "bash", "-c",
            "nmcli -t -f active,ssid,signal dev wifi 2>/dev/null | grep '^yes' | head -1"
        ]
        stdout: SplitParser {
            onRead: line => {
                const p = line.trim().split(":")
                root.ssid   = p[1] || "Unknown"
                root.signal = parseInt(p[2]) || 0
            }
        }
    }

    // Network speed — single /proc/net/dev read every 2s, delta from previous
    Timer {
        id: speedTimer
        interval: 2000
        running: root.active && root.ifaceName !== "" && root.connType !== "none"
        repeat: true
        triggeredOnStart: true
        onTriggered: speedProc.running = true
    }

    Process {
        id: speedProc
        command: [
            "bash", "-c",
            "awk -v i='" + root.ifaceName + ":' '$1==i {print $2, $10}' /proc/net/dev"
        ]
        stdout: SplitParser {
            onRead: line => {
                const p = line.trim().split(" ")
                const rx = parseFloat(p[0]) || 0
                const tx = parseFloat(p[1]) || 0
                if (root._prevRx > 0) {
                    const dt = speedTimer.interval / 1000
                    root.downSpeed = root.formatSpeed((rx - root._prevRx) / dt)
                    root.upSpeed   = root.formatSpeed((tx - root._prevTx) / dt)
                }
                root._prevRx = rx
                root._prevTx = tx
            }
        }
    }

    // Reset counters when interface changes so first delta isn't stale
    onIfaceNameChanged: { root._prevRx = 0; root._prevTx = 0 }

    Column {
        id: col
        width: parent.width
        spacing: 0

        SectionHeader {
            width: parent.width
            label: "NETWORK"
            accent: Colors.green
        }

        Rectangle {
            width: parent.width
            height: 66
            color: Colors.surface0
            radius: 8

            Column {
                anchors {
                    left: parent.left; right: parent.right
                    leftMargin: 12; rightMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                spacing: 6

                Row {
                    width: parent.width
                    spacing: 10

                    Text {
                        text: root.connType === "wifi"    ? "" :
                              root.connType === "ethernet" ? "󰈀" : "󰤭"
                        font.pixelSize: 18
                        color: root.connType === "none" ? Colors.red : Colors.green
                        font.family: "JetBrainsMono Nerd Font"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Text {
                            text: root.connType === "wifi"    ? root.ssid :
                                  root.connType === "ethernet" ? root.connName :
                                  "Disconnected"
                            font.pixelSize: 13
                            color: Colors.text
                        }
                        Text {
                            visible: root.connType !== "none"
                            text: root.connType === "wifi" ? root.signal + "% signal" : "Ethernet"
                            font.pixelSize: 10
                            color: Colors.subtext0
                        }
                    }

                    Row {
                        visible: root.connType === "wifi"
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3

                        Repeater {
                            model: 4
                            delegate: Rectangle {
                                width: 4
                                height: 6 + index * 4
                                anchors.bottom: parent.bottom
                                radius: 2
                                color: root.signal >= (index + 1) * 25 ? Colors.green : Colors.surface1
                            }
                        }
                    }
                }

                Row {
                    visible: root.connType !== "none"
                    spacing: 16

                    Row {
                        spacing: 4
                        Text {
                            text: "↓"
                            font.pixelSize: 11
                            color: Colors.blue
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: root.downSpeed
                            font.pixelSize: 11
                            color: Colors.subtext0
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Row {
                        spacing: 4
                        Text {
                            text: "↑"
                            font.pixelSize: 11
                            color: Colors.peach
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: root.upSpeed
                            font.pixelSize: 11
                            color: Colors.subtext0
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }
}

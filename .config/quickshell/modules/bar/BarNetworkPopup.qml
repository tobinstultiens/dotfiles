import Quickshell
import Quickshell.Io
import QtQuick
import Qs
import "../.." 1.0

PanelWindow {
    id: root

    property bool open:   false
    property real popupX: 8
    signal closeRequested()

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    visible: open || closeTimer.running
    onOpenChanged: {
        if (open) networkList.refresh()
        else closeTimer.start()
    }
    Timer { id: closeTimer; interval: 220 }

    MouseArea { anchors.fill: parent; onClicked: root.closeRequested() }

    // ── Network data model ────────────────────────────────────────────────
    QtObject {
        id: networkList

        property var  networks:     []   // [{ssid, signal, secured, active}]
        property bool wifiEnabled:  true
        property bool loading:      false
        property bool scanning:     false
        property string _buf:       ""
        property string _wifiBuf:   ""

        function refresh() {
            loading = true
            wifiStateProc.running = true
        }

        function connect(ssid) {
            connectProc.command = ["bash", "-c",
                "nmcli dev wifi connect \"" + ssid.replace(/"/g, '\\"') + "\" 2>/dev/null || true"]
            connectProc.running = true
        }

        function disconnect() {
            disconnectProc.running = true
        }

        function toggleWifi() {
            toggleProc.command = ["nmcli", "radio", "wifi", wifiEnabled ? "off" : "on"]
            toggleProc.running = true
        }

        function rescan() {
            scanning = true
            rescanProc.running = true
        }

        property var _impl: Item {

            Process {
                id: wifiStateProc
                command: ["bash", "-c", "nmcli radio wifi 2>/dev/null"]
                stdout: SplitParser { onRead: line => { networkList._wifiBuf += line.trim() } }
                onExited: {
                    networkList.wifiEnabled = networkList._wifiBuf.trim() === "enabled"
                    networkList._wifiBuf    = ""
                    listProc.running = true
                }
            }

            Process {
                id: listProc
                // ssid:signal:security:active — sorted by signal desc
                command: ["bash", "-c",
                    "nmcli -t -f SSID,SIGNAL,SECURITY,ACTIVE dev wifi list 2>/dev/null | sort -t: -k2 -rn"]
                stdout: SplitParser { onRead: line => { networkList._buf += line + "\n" } }
                onExited: {
                    var seen = {}
                    var nets = []
                    var lines = networkList._buf.trim().split("\n").filter(l => l.length > 0)
                    for (var i = 0; i < lines.length; i++) {
                        var parts = lines[i].split(":")
                        if (parts.length < 4) continue
                        var ssid = parts[0]
                        if (!ssid || seen[ssid]) continue
                        seen[ssid] = true
                        nets.push({
                            ssid:    ssid,
                            signal:  parseInt(parts[1]) || 0,
                            secured: parts[2] !== "",
                            active:  parts[3] === "yes"
                        })
                    }
                    networkList.networks = nets
                    networkList.loading  = false
                    networkList._buf     = ""
                }
            }

            Process {
                id: connectProc
                onExited: networkList.refresh()
            }

            Process {
                id: disconnectProc
                command: ["bash", "-c", "nmcli dev disconnect \"$(nmcli -t -f DEVICE,TYPE dev | awk -F: '$2==\"wifi\"{print $1;exit}')\" 2>/dev/null || true"]
                onExited: networkList.refresh()
            }

            Process {
                id: toggleProc
                onExited: networkList.refresh()
            }

            Process {
                id: rescanProc
                command: ["bash", "-c", "nmcli dev wifi rescan 2>/dev/null; sleep 2"]
                onExited: { networkList.scanning = false; networkList.refresh() }
            }
        }
    }

    Rectangle {
        id: panel
        width: 300
        height: content.implicitHeight + 30

        x: Math.max(4, Math.min(root.popupX, root.width - width - 4))
        y: root.open ? 44 : -(height + 44)
        Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        color: Colors.mantle
        radius: 12

        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 12; color: Colors.mantle
        }

        MouseArea { anchors.fill: parent }

        Column {
            id: content
            anchors {
                top: parent.top; topMargin: 16
                left: parent.left; leftMargin: 16
                right: parent.right; rightMargin: 16
            }
            spacing: 10

            // Header row: NETWORK label + WiFi toggle
            Row {
                width: parent.width

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "NETWORK"
                    font.pixelSize: 10; font.letterSpacing: 2
                    font.family: "JetBrainsMono Nerd Font"
                    color: Colors.overlay1
                }

                Item { width: parent.width - parent.children[0].width - wifiSwitch.width - 8; height: 1 }

                // WiFi on/off pill
                Rectangle {
                    id: wifiSwitch
                    anchors.verticalCenter: parent.verticalCenter
                    width: 44; height: 24; radius: 12
                    color: networkList.wifiEnabled
                           ? Qt.rgba(Colors.green.r, Colors.green.g, Colors.green.b, 0.2)
                           : Colors.surface0
                    border.width: 1
                    border.color: networkList.wifiEnabled ? Colors.green : Colors.surface2
                    Behavior on color        { ColorAnimation { duration: 200 } }
                    Behavior on border.color { ColorAnimation { duration: 200 } }

                    Rectangle {
                        width: 16; height: 16; radius: 8
                        anchors.verticalCenter: parent.verticalCenter
                        x: networkList.wifiEnabled ? 24 : 4
                        color: networkList.wifiEnabled ? Colors.green : Colors.overlay1
                        Behavior on x     { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation  { duration: 200 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: networkList.toggleWifi()
                    }
                }
            }

            // Network list
            Repeater {
                model: networkList.networks.slice(0, 8)

                Item {
                    id: netItem
                    required property var modelData
                    width: content.width
                    implicitHeight: 32

                    // Signal icon
                    Text {
                        id: sigIcon
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                        text: {
                            const s = netItem.modelData.signal
                            if (s >= 80) return "󰤨"
                            if (s >= 60) return "󰤥"
                            if (s >= 40) return "󰤢"
                            if (s >= 20) return "󰤟"
                            return "󰤯"
                        }
                        font.pixelSize: 16; font.family: "JetBrainsMono Nerd Font"
                        color: netItem.modelData.active ? Colors.green : Colors.overlay1
                    }

                    // Lock icon for secured networks
                    Text {
                        anchors {
                            left: sigIcon.right; leftMargin: 4
                            verticalCenter: parent.verticalCenter
                        }
                        visible: netItem.modelData.secured
                        text: "󰌾"
                        font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"
                        color: Colors.overlay0
                    }

                    // SSID
                    Text {
                        anchors {
                            left: sigIcon.right; leftMargin: netItem.modelData.secured ? 18 : 6
                            right: connectNetBtn.left; rightMargin: 8
                            verticalCenter: parent.verticalCenter
                        }
                        text: netItem.modelData.ssid
                        font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"
                        font.weight: netItem.modelData.active ? Font.Medium : Font.Normal
                        color: netItem.modelData.active ? Colors.text : Colors.subtext0
                        elide: Text.ElideRight
                    }

                    // Connect/disconnect button
                    Rectangle {
                        id: connectNetBtn
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        width: 56; height: 22; radius: 11
                        color: netItem.modelData.active ? Colors.green : Colors.surface0
                        border.width: 1
                        border.color: netItem.modelData.active ? Colors.green : Colors.surface2

                        Text {
                            anchors.centerIn: parent
                            text: netItem.modelData.active ? "Disconnect" : "Connect"
                            font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font"
                            color: netItem.modelData.active ? Colors.base : Colors.subtext0
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: netItem.modelData.active
                                       ? networkList.disconnect()
                                       : networkList.connect(netItem.modelData.ssid)
                        }
                    }
                }
            }

            // Empty/loading states
            Text {
                visible: networkList.loading
                text: "Loading…"
                font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"
                color: Colors.overlay0
            }

            Text {
                visible: !networkList.loading && networkList.networks.length === 0 && networkList.wifiEnabled
                text: "No networks found"
                font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"
                color: Colors.overlay0
            }

            // Rescan button
            Rectangle {
                width: parent.width; height: 30; radius: 8
                color: Colors.surface0
                border.width: 1
                border.color: Colors.surface1
                visible: networkList.wifiEnabled

                Row {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: networkList.scanning ? "󰑐" : "󰑐"
                        font.pixelSize: 13; font.family: "JetBrainsMono Nerd Font"
                        color: Colors.subtext0

                        RotationAnimation on rotation {
                            running: networkList.scanning
                            loops: Animation.Infinite
                            from: 0; to: 360; duration: 1000
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: networkList.scanning ? "Scanning…" : "Rescan"
                        font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"
                        color: Colors.subtext0
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !networkList.scanning
                    onClicked: networkList.rescan()
                }
            }
        }
    }
}

import Quickshell
import Quickshell.Bluetooth
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
    onOpenChanged: if (!open) closeTimer.start()
    Timer { id: closeTimer; interval: 220 }

    readonly property var adapter: Bluetooth.defaultAdapter

    MouseArea { anchors.fill: parent; onClicked: root.closeRequested() }

    Rectangle {
        id: panel
        width: 280
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

            Text {
                text: "BLUETOOTH"
                font.pixelSize: 10; font.letterSpacing: 2
                font.family: "JetBrainsMono Nerd Font"
                color: Colors.overlay1
            }

            // Enable / Discover toggles
            BtToggleRow {
                width: parent.width
                label:     "Enabled"
                checked:   root.adapter ? root.adapter.enabled : false
                onToggled: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
            }

            BtToggleRow {
                width: parent.width
                label:     "Discover"
                checked:   root.adapter ? root.adapter.discovering : false
                onToggled: if (root.adapter) root.adapter.discovering = !root.adapter.discovering
            }

            Rectangle { width: parent.width; height: 1; color: Colors.surface1 }

            // Device count
            Text {
                visible: deviceRepeater.count === 0
                text: root.adapter && root.adapter.enabled ? "No devices found" : "Bluetooth off"
                font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"
                color: Colors.overlay0
            }

            // Device list — sorted: connected first, then paired, then by name
            Repeater {
                id: deviceRepeater
                model: {
                    if (!root.adapter) return []
                    return [...Bluetooth.devices.values]
                        .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired)
                              || a.name.localeCompare(b.name))
                        .slice(0, 6)
                }

                Item {
                    id: deviceItem
                    required property BluetoothDevice modelData
                    width: content.width
                    implicitHeight: 36

                    readonly property bool isConnecting:
                        modelData.state === BluetoothDeviceState.Connecting ||
                        modelData.state === BluetoothDeviceState.Disconnecting

                    // Device icon
                    Text {
                        id: deviceIcon
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                        text: {
                            const ic = deviceItem.modelData.icon || ""
                            if (ic.includes("headphone") || ic.includes("headset")) return "󰋋"
                            if (ic.includes("mouse"))                               return "󰍽"
                            if (ic.includes("keyboard"))                            return "󰌌"
                            if (ic.includes("phone"))                               return "󰄕"
                            if (ic.includes("audio"))                               return "󰓃"
                            return "󰂯"
                        }
                        font.pixelSize: 16; font.family: "JetBrainsMono Nerd Font"
                        color: deviceItem.modelData.connected ? Colors.blue : Colors.overlay1
                    }

                    // Device name
                    Column {
                        anchors {
                            left: deviceIcon.right; leftMargin: 10
                            right: connectBtn.left; rightMargin: 8
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 1

                        Text {
                            width: parent.width
                            text: deviceItem.modelData.name
                            font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"
                            color: deviceItem.modelData.connected ? Colors.text : Colors.subtext0
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: deviceItem.modelData.batteryAvailable
                            text: Math.round(deviceItem.modelData.battery * 100) + "% battery"
                            font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"
                            color: Colors.overlay0
                        }
                    }

                    // Connect/disconnect button
                    Rectangle {
                        id: connectBtn
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        width: 60; height: 24; radius: 12
                        color: deviceItem.modelData.connected ? Colors.blue : Colors.surface0
                        border.width: 1
                        border.color: deviceItem.modelData.connected ? Colors.blue : Colors.surface2
                        opacity: deviceItem.isConnecting ? 0.5 : 1

                        Text {
                            anchors.centerIn: parent
                            text: deviceItem.isConnecting ? "…"
                                : deviceItem.modelData.connected ? "Disconnect" : "Connect"
                            font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"
                            color: deviceItem.modelData.connected ? Colors.base : Colors.subtext0
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: !deviceItem.isConnecting
                            onClicked: deviceItem.modelData.connected =
                                       !deviceItem.modelData.connected
                        }
                    }
                }
            }
        }
    }

    component BtToggleRow: Item {
        property string label:   ""
        property bool   checked: false
        signal toggled

        implicitHeight: 28
        width: parent ? parent.width : 0

        Text {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            text: parent.label
            font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"
            color: Colors.text
        }

        // Toggle switch
        Item {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            width: 44; height: 24

            Rectangle {
                anchors.fill: parent; radius: 12
                color: parent.parent.checked
                       ? Qt.rgba(Colors.blue.r, Colors.blue.g, Colors.blue.b, 0.25)
                       : Colors.surface0
                border.width: 1
                border.color: parent.parent.checked ? Colors.blue : Colors.surface2
                Behavior on color        { ColorAnimation { duration: 200 } }
                Behavior on border.color { ColorAnimation { duration: 200 } }
            }

            Rectangle {
                width: 16; height: 16; radius: 8
                anchors.verticalCenter: parent.verticalCenter
                x: parent.parent.checked ? 24 : 4
                color: parent.parent.checked ? Colors.blue : Colors.overlay1
                Behavior on x     { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation  { duration: 200 } }
            }

            MouseArea { anchors.fill: parent; onClicked: parent.parent.toggled() }
        }
    }
}

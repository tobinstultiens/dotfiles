import Quickshell
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
    Timer { id: closeTimer; interval: 220 }
    onOpenChanged: if (!open) closeTimer.start()

    MouseArea {
        anchors.fill: parent
        onClicked: root.closeRequested()
    }

    Rectangle {
        id: panel
        width: 260
        height: content.implicitHeight + 30

        x: root.popupX
        y: root.open ? 44 : -(height + 44)
        Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        color: Colors.mantle
        radius: 12

        // Square off top corners so it looks attached to the bar
        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 12
            color: Colors.mantle
        }

        MouseArea { anchors.fill: parent }

        Column {
            id: content
            anchors {
                top: parent.top; topMargin: 16
                left: parent.left; leftMargin: 16
                right: parent.right; rightMargin: 16
            }
            spacing: 12

            Text {
                text: "VPN"
                font.pixelSize: 10
                font.family: "JetBrainsMono Nerd Font"
                font.letterSpacing: 2
                color: Colors.overlay1
            }

            // PIA row
            VPNRow {
                width: parent.width
                label:       "Private Internet Access"
                icon:        "󰦝"
                connected:   VPNService.piaConnected
                connecting:  VPNService.piaState === "Connecting" || VPNService.piaState === "Reconnecting"
                detail:      {
                    if (VPNService.piaState === "Connecting")    return "Connecting…"
                    if (VPNService.piaState === "Reconnecting")  return "Reconnecting…"
                    if (VPNService.piaConnected && VPNService.piaRegion !== "")
                        return VPNService.piaRegion + (VPNService.piaIp !== "" ? "  ·  " + VPNService.piaIp : "")
                    return ""
                }
                accentColor: Colors.green
                onToggled:   VPNService.piaToggle()
            }

            Rectangle { width: parent.width; height: 1; color: Colors.surface1 }

            // Tailscale row
            VPNRow {
                width: parent.width
                label:       "Tailscale"
                icon:        "󰈀"
                connected:   VPNService.tsConnected
                connecting:  false
                detail:      VPNService.tsConnected && VPNService.tsIp !== "" ? VPNService.tsIp : ""
                accentColor: Colors.mauve
                onToggled:   VPNService.tsToggle()
            }
        }
    }

    component VPNRow: Item {
        id: vpnRow
        property string label:       ""
        property string icon:        ""
        property bool   connected:   false
        property bool   connecting:  false
        property string detail:      ""
        property color  accentColor: Colors.blue
        signal toggled

        implicitHeight: 40

        Rectangle {
            id: iconBox
            width: 34; height: 34
            radius: 9
            anchors.verticalCenter: parent.verticalCenter
            color: (vpnRow.connected || vpnRow.connecting)
                   ? Qt.rgba(vpnRow.accentColor.r, vpnRow.accentColor.g, vpnRow.accentColor.b, 0.18)
                   : Colors.surface0
            Behavior on color { ColorAnimation { duration: 200 } }

            Text {
                anchors.centerIn: parent
                text: vpnRow.icon
                font.pixelSize: 17
                font.family: "JetBrainsMono Nerd Font"
                color: vpnRow.connected ? vpnRow.accentColor
                     : vpnRow.connecting ? Qt.rgba(vpnRow.accentColor.r, vpnRow.accentColor.g,
                                                   vpnRow.accentColor.b, 0.5)
                     : Colors.overlay1
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }

        Column {
            anchors {
                left: iconBox.right; leftMargin: 10
                right: toggleSwitch.left; rightMargin: 10
                verticalCenter: parent.verticalCenter
            }
            spacing: 2

            Text {
                width: parent.width
                text: vpnRow.label
                font.pixelSize: 12
                font.family: "JetBrainsMono Nerd Font"
                color: Colors.text
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: vpnRow.connecting  ? vpnRow.detail
                    : vpnRow.connected   ? (vpnRow.detail !== "" ? vpnRow.detail : "Connected")
                    : "Disconnected"
                font.pixelSize: 10
                font.family: "JetBrainsMono Nerd Font"
                color: vpnRow.connected  ? vpnRow.accentColor
                     : vpnRow.connecting ? Qt.rgba(vpnRow.accentColor.r, vpnRow.accentColor.g,
                                                   vpnRow.accentColor.b, 0.6)
                     : Colors.overlay0
                elide: Text.ElideRight
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }

        Item {
            id: toggleSwitch
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            width: 44; height: 24

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: vpnRow.connected
                       ? Qt.rgba(vpnRow.accentColor.r, vpnRow.accentColor.g, vpnRow.accentColor.b, 0.25)
                       : Colors.surface0
                border.width: 1
                border.color: vpnRow.connected ? vpnRow.accentColor : Colors.surface2
                Behavior on color        { ColorAnimation { duration: 200 } }
                Behavior on border.color { ColorAnimation { duration: 200 } }
            }

            Rectangle {
                width: 16; height: 16
                radius: 8
                anchors.verticalCenter: parent.verticalCenter
                x: vpnRow.connected ? 24 : 4
                color: vpnRow.connected  ? vpnRow.accentColor
                     : vpnRow.connecting ? Qt.rgba(vpnRow.accentColor.r, vpnRow.accentColor.g,
                                                   vpnRow.accentColor.b, 0.5)
                     : Colors.overlay1
                Behavior on x     { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation  { duration: 200 } }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: vpnRow.toggled()
            }
        }
    }
}

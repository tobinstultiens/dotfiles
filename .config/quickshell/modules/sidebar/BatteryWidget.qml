import Quickshell.Services.UPower
import QtQuick
import Qs

Item {
    id: root

    readonly property UPowerDevice battery: UPower.displayDevice
    readonly property bool hasBattery: battery !== null && battery.isLaptopBattery

    implicitHeight: visible ? card.implicitHeight : 0
    visible: hasBattery

    Rectangle {
        id: card
        width: parent.width
        height: 50
        color: Colors.surface0
        radius: 8

        Row {
            anchors { left: parent.left; right: parent.right; leftMargin: 12; rightMargin: 12; verticalCenter: parent.verticalCenter }
            spacing: 10

            Text {
                text: root.hasBattery ? (root.battery.isCharging ? "󰂄" : "󰁹") : "󰁹"
                font.pixelSize: 20
                color: !root.hasBattery          ? Colors.overlay0 :
                       root.battery.percentage < 20 ? Colors.red :
                       root.battery.percentage < 50 ? Colors.yellow : Colors.green
                font.family: "JetBrainsMono Nerd Font"
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Text {
                    text: "Battery  " + (root.hasBattery ? Math.round(root.battery.percentage) : 0) + "%"
                    font.pixelSize: 13
                    color: Colors.text
                }

                Rectangle {
                    width: 160; height: 5; radius: 3; color: Colors.surface1
                    Rectangle {
                        width: parent.width * (root.hasBattery ? root.battery.percentage / 100 : 0)
                        height: parent.height; radius: parent.radius
                        color: !root.hasBattery              ? Colors.overlay0 :
                               root.battery.percentage < 20  ? Colors.red :
                               root.battery.percentage < 50  ? Colors.yellow : Colors.green
                        Behavior on width { NumberAnimation { duration: 500 } }
                    }
                }
            }
        }
    }
}

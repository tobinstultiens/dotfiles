import Quickshell.Services.UPower
import QtQuick
import "../.." 1.0

Item {
    id: root
    required property string nativePath
    required property string icon

    implicitHeight: parent.height
    implicitWidth: visible ? pill.implicitWidth : 0

    readonly property UPowerDevice device: {
        const devs = UPower.devices.values
        for (let i = 0; i < devs.length; i++) {
            if (devs[i].nativePath === root.nativePath) return devs[i]
        }
        return null
    }

    visible: device !== null

    Rectangle {
        id: pill
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: lbl.implicitWidth + 20
        height: Colors.pillHeight
        radius: 8
        color: Colors.surface0

        Text {
            id: lbl
            anchors.centerIn: parent
            text: root.icon + "  " + (root.device ? Math.round(root.device.percentage) : 0) + "%"
            font.pixelSize: 13
            font.family: "JetBrainsMono Nerd Font"
            color: Colors.text
        }
    }
}

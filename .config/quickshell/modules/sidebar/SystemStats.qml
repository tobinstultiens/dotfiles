import QtQuick
import QtQuick.Layouts
import "../.." 1.0

Item {
    id: root
    required property var sysInfo
    implicitHeight: col.implicitHeight

    Column {
        id: col
        width: parent.width
        spacing: 6

        Text {
            text: "SYSTEM"
            font.pixelSize: 10
            font.weight: Font.Medium
            color: Colors.overlay1
            leftPadding: 2
            bottomPadding: 2
        }

        StatRow {
            width: parent.width
            label: "CPU"
            value: Math.round(root.sysInfo.cpuPercent) + "%"
            percent: root.sysInfo.cpuPercent
            barColor: Colors.blue
        }

        StatRow {
            width: parent.width
            label: "RAM"
            value: root.sysInfo.ramUsedGb.toFixed(1) + " / " + root.sysInfo.ramTotalGb.toFixed(1) + " GB"
            percent: root.sysInfo.ramPercent
            barColor: Colors.mauve
        }

        StatRow {
            width: parent.width
            label: "Disk"
            value: root.sysInfo.diskUsed + " / " + root.sysInfo.diskTotal
            percent: root.sysInfo.diskPercent
            barColor: Colors.peach
        }

        StatRow {
            width: parent.width
            label: "Up"
            value: root.sysInfo.uptime
            percent: -1
            barColor: "transparent"
        }
    }

    component StatRow: Item {
        required property string label
        required property string value
        required property real   percent
        required property color  barColor

        implicitHeight: 38

        Rectangle {
            anchors.fill: parent
            color: Colors.surface0
            radius: 8
        }

        Text {
            id: lbl
            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
            text: parent.label
            font.pixelSize: 11
            color: Colors.subtext0
            width: 30
        }

        Rectangle {
            id: barBg
            visible: parent.percent >= 0
            anchors {
                left: lbl.right; leftMargin: 8
                right: val.left; rightMargin: 8
                verticalCenter: parent.verticalCenter
            }
            height: 5; radius: 3
            color: Colors.surface1

            Rectangle {
                width: barBg.width * Math.max(0, Math.min(100, parent.parent.percent)) / 100
                height: parent.height; radius: parent.radius
                color: parent.parent.barColor
                Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
            }
        }

        Text {
            id: val
            anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
            text: parent.value
            font.pixelSize: 11
            color: Colors.text
        }
    }
}

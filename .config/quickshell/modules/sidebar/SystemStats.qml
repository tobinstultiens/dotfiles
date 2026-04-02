import QtQuick
import QtQuick.Layouts
import Qs

Item {
    id: root
    implicitHeight: col.implicitHeight

    Column {
        id: col
        width: parent.width
        spacing: 6

        SectionHeader {
            width: parent.width
            label: "SYSTEM"
            accent: Colors.blue
        }

        StatRow {
            width: parent.width
            label: "CPU"
            value: Math.round(SystemInfo.cpuPercent) + "%"
            percent: SystemInfo.cpuPercent
            barColor: Colors.blue
        }

        StatRow {
            width: parent.width
            label: "RAM"
            value: SystemInfo.ramUsedGb.toFixed(1) + " / " + SystemInfo.ramTotalGb.toFixed(1) + " GB"
            percent: SystemInfo.ramPercent
            barColor: Colors.mauve
        }

        StatRow {
            width: parent.width
            label: "Disk"
            value: SystemInfo.diskUsed + " / " + SystemInfo.diskTotal
            percent: SystemInfo.diskPercent
            barColor: Colors.peach
        }

        StatRow {
            width: parent.width
            label: "Up"
            value: SystemInfo.uptime
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

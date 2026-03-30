import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../.." 1.0

Item {
    id: root
    implicitHeight: col.implicitHeight

    property string pendingAction: ""
    readonly property bool confirming: pendingAction !== ""

    Process {
        id: actionProc
        property string cmd: ""
        command: ["bash", "-c", actionProc.cmd]
    }

    function confirm(cmd) {
        root.pendingAction = cmd
    }

    function execute(cmd) {
        root.pendingAction = ""
        actionProc.cmd = cmd
        actionProc.running = true
    }

    Column {
        id: col
        width: parent.width
        spacing: 8

        Text {
            text: "SESSION"
            font.pixelSize: 10
            font.weight: Font.Medium
            color: Colors.overlay1
            leftPadding: 2
        }

        // Normal button grid
        GridLayout {
            id: grid
            visible: !root.confirming
            width: parent.width
            columns: 2
            columnSpacing: 8
            rowSpacing: 8

            PowerBtn {
                Layout.fillWidth: true
                label: "Shutdown"
                icon: "󰐥"
                btnColor: Colors.red
                onTap: root.confirm("systemctl poweroff")
            }
            PowerBtn {
                Layout.fillWidth: true
                label: "Reboot"
                icon: "󰑓"
                btnColor: Colors.peach
                onTap: root.confirm("systemctl reboot")
            }
            PowerBtn {
                Layout.fillWidth: true
                label: "Logout"
                icon: "󰍃"
                btnColor: Colors.yellow
                onTap: root.confirm("hyprctl dispatch exit 0")
            }
            PowerBtn {
                Layout.fillWidth: true
                label: "Lock"
                icon: "󰌾"
                btnColor: Colors.blue
                onTap: root.execute("hyprlock")
            }
        }

        // Confirmation prompt
        Column {
            visible: root.confirming
            width: parent.width
            spacing: 10

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "Are you sure?"
                font.pixelSize: 13
                color: Colors.text
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12

                Rectangle {
                    width: 110; height: 38; radius: 8; color: Colors.red

                    Text {
                        anchors.centerIn: parent
                        text: "Confirm"
                        color: Colors.base
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.execute(root.pendingAction)
                    }
                }

                Rectangle {
                    width: 110; height: 38; radius: 8; color: Colors.surface1

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: Colors.text
                        font.pixelSize: 13
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.pendingAction = ""
                    }
                }
            }
        }
    }

    component PowerBtn: Rectangle {
        required property string label
        required property string icon
        required property color  btnColor
        signal tap

        implicitHeight: 48
        radius: 8
        color: ma.containsMouse
               ? Qt.rgba(btnColor.r, btnColor.g, btnColor.b, 0.2)
               : Colors.surface0

        Behavior on color { ColorAnimation { duration: 120 } }

        Row {
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: parent.parent.icon
                font.pixelSize: 17
                color: parent.parent.btnColor
                font.family: "JetBrainsMono Nerd Font"
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: parent.parent.label
                font.pixelSize: 12
                color: Colors.text
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            onClicked: parent.tap()
        }
    }
}

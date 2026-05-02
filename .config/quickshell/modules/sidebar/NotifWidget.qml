import Quickshell.Services.Notifications
import QtQuick
import Qs
import "../.." 1.0

Item {
    id: root
    implicitHeight: col.implicitHeight
    visible: NotificationService.model.values.length > 0

    Column {
        id: col
        width: parent.width
        spacing: 0

        // Header with clear-all button
        Item {
            width: parent.width
            height: sectionRow.implicitHeight + 8

            Row {
                id: sectionRow
                width: parent.width

                SectionHeader { width: parent.width - clearBtn.width; label: "NOTIFICATIONS"; accent: Colors.peach }

                Text {
                    id: clearBtn
                    text: "Clear"
                    font.pixelSize: 11
                    font.family: "JetBrainsMono Nerd Font"
                    color: Colors.overlay1
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        onClicked: NotificationService.clearAll()
                    }
                }
            }
        }

        Column {
            width: parent.width
            spacing: 6

            Repeater {
                model: NotificationService.model

                Rectangle {
                    width: parent.width
                    implicitHeight: notifContent.implicitHeight + 14
                    radius: 8
                    color: Colors.surface0

                    // Urgency bar
                    Rectangle {
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                        width: 3; radius: 3
                        color: modelData.urgency === NotificationUrgency.Critical ? Colors.red
                             : modelData.urgency === NotificationUrgency.Low      ? Colors.overlay0
                             : Colors.blue
                    }

                    Column {
                        id: notifContent
                        anchors {
                            left: parent.left; leftMargin: 12
                            right: parent.right; rightMargin: 10
                            top: parent.top; topMargin: 10
                        }
                        spacing: 2

                        Row {
                            spacing: 6
                            Text {
                                text: modelData.appName || ""
                                font.pixelSize: 10
                                font.family: "JetBrainsMono Nerd Font"
                                color: Colors.overlay1
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Item { width: parent.parent.width - 100; height: 1 }
                            Text {
                                text: "󰅙"
                                font.pixelSize: 12
                                font.family: "JetBrainsMono Nerd Font"
                                color: Colors.overlay0
                                anchors.verticalCenter: parent.verticalCenter
                                MouseArea { anchors.fill: parent; onClicked: modelData.dismiss() }
                            }
                        }

                        Text {
                            width: parent.width
                            text: modelData.summary || ""
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            font.family: "JetBrainsMono Nerd Font"
                            color: Colors.text
                            elide: Text.ElideRight
                            visible: text !== ""
                        }

                        Text {
                            width: parent.width
                            text: modelData.body || ""
                            font.pixelSize: 11
                            font.family: "JetBrainsMono Nerd Font"
                            color: Colors.subtext0
                            elide: Text.ElideRight
                            maximumLineCount: 2
                            visible: text !== ""
                        }
                    }
                }
            }
        }
    }
}

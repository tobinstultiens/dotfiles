import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import "../.." 1.0

Item {
    id: root
    required property var barWindow
    implicitHeight: parent.height
    implicitWidth: trayRow.implicitWidth

    Row {
        id: trayRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Repeater {
            model: SystemTray.items

            delegate: Item {
                required property SystemTrayItem modelData
                property SystemTrayItem item: modelData

                width: 20
                height: 20
                anchors.verticalCenter: parent.verticalCenter

                IconImage {
                    anchors.fill: parent
                    source: parent.item.icon
                    implicitSize: 16
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            parent.item.activate()
                        } else {
                            parent.item.display(
                                root.barWindow,
                                mapToItem(null, mouse.x, 0).x,
                                root.barWindow.implicitHeight
                            )
                        }
                    }
                }
            }
        }
    }
}

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
                id: delegateItem
                required property SystemTrayItem modelData
                property SystemTrayItem item: modelData

                width: 20
                height: 20
                anchors.verticalCenter: parent.verticalCenter

                IconImage {
                    id: trayIcon
                    anchors.fill: parent
                    source: delegateItem.item.icon
                    implicitSize: 16
                }

                QsMenuAnchor {
                    id: menuAnchor
                    menu: delegateItem.item.menu
                    anchor.window: root.barWindow
                    anchor.item: trayIcon
                    anchor.edges: Edges.Bottom
                    anchor.gravity: Edges.Bottom
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            delegateItem.item.activate()
                        } else {
                            menuAnchor.open()
                        }
                    }
                }
            }
        }
    }
}

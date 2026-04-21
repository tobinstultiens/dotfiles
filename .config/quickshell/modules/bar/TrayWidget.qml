import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import Qs

Item {
    id: root
    required property var barWindow
    implicitHeight: parent.height
    implicitWidth: trayRow.implicitWidth

    function resolveIcon(raw) {
        if (raw === "image://icon/drive-removable-media")
            return "file:///usr/share/icons/AdwaitaLegacy/32x32/devices/drive-removable-media.png"
        if (raw.includes("spotify-linux-"))
            return "file:///opt/spotify/icons/spotify-linux-32.png"
        return raw
    }

    Row {
        id: trayRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Repeater {
            id: trayRepeater
            model: SystemTray.items.values

            delegate: Item {
                id: delegateItem
                required property var modelData
                property SystemTrayItem item: modelData

                width: 20
                height: 20
                anchors.verticalCenter: parent.verticalCenter

                IconImage {
                    id: trayIcon
                    anchors.fill: parent
                    source: root.resolveIcon(delegateItem.item.icon)
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

import Quickshell
import Quickshell.Wayland
import QtQuick
import Qs

PanelWindow {
    id: root

    property bool open: false

    visible: open || hideTimer.running
    onOpenChanged: if (!open) hideTimer.start()

    Timer {
        id: hideTimer
        interval: 280
        repeat: false
    }

    implicitWidth: 400

    anchors {
        right: true
        top: true
        bottom: true
    }

    exclusionMode: ExclusionMode.Ignore
    focusable: true
    color: "transparent"

    Rectangle {
        id: panel
        anchors {
            top: parent.top
            bottom: parent.bottom
            right: parent.right
        }
        width: root.width
        color: Colors.base

        property real slideX: root.open ? 0 : root.width
        transform: Translate { x: panel.slideX }
        Behavior on slideX {
            NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
        }

        Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: 1
            color: Colors.surface1
        }

        // Scrollable content area
        Flickable {
            id: scrollArea
            anchors {
                top: parent.top; topMargin: 14
                left: parent.left; leftMargin: 14
                right: parent.right; rightMargin: 14
                bottom: footer.top; bottomMargin: 8
            }
            contentHeight: content.implicitHeight
            clip: true

            Column {
                id: content
                width: scrollArea.width
                spacing: 16

                ClockCalendar {
                    width: parent.width
                }

                SystemStats {
                    width: parent.width
                }

                NetworkWidget {
                    width: parent.width
                    active: root.open
                }

                BrightnessWidget {
                    width: parent.width
                    active: root.open
                }

                MediaWidget {
                    width: parent.width
                }

                WeatherWidget {
                    width: parent.width
                }

                BatteryWidget {
                    width: parent.width
                }

                NotifWidget {
                    width: parent.width
                }

                NotesWidget {
                    width: parent.width
                }
            }
        }

        Item {
            id: footer
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: 14
            }
            implicitHeight: powerBtns.implicitHeight
            height: implicitHeight

            PowerButtons {
                id: powerBtns
                width: parent.width
            }
        }
    }
}

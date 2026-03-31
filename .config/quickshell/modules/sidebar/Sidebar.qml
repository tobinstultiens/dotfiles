import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import "../.." 1.0

PanelWindow {
    id: root

    // Start hidden; toggled via IPC
    property bool open: false

    // Keep the surface alive during the slide-out animation, then remove it
    visible: open || hideTimer.running
    onOpenChanged: if (!open) hideTimer.start()

    Timer {
        id: hideTimer
        interval: 280   // slightly longer than the 260ms animation
        repeat: false
    }

    implicitWidth: 300

    anchors {
        right: true
        top: true
        bottom: true
    }

    // Overlay apps — don't shrink window area
    exclusionMode: ExclusionMode.Ignore

    // Allow keyboard/mouse focus inside
    focusable: true

    color: "transparent"

    // Slide animation container
    Rectangle {
        id: panel
        anchors {
            top: parent.top
            bottom: parent.bottom
            right: parent.right
        }
        width: root.width
        color: Colors.base

        // Slide in from right using an intermediate property
        property real slideX: root.open ? 0 : root.width
        transform: Translate { x: panel.slideX }
        Behavior on slideX {
            NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
        }

        // Subtle left border
        Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: 1
            color: Colors.surface1
        }

        Flickable {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                bottom: footer.top
                topMargin: 14
                leftMargin: 14
                rightMargin: 14
            }
            contentHeight: content.implicitHeight
            clip: true
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            Column {
                id: content
                width: parent.width
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

                BatteryWidget {
                    width: parent.width
                }
            }
        }

        // Divider + pinned session buttons
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: footer.top }
            height: 1
            color: Colors.surface1
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

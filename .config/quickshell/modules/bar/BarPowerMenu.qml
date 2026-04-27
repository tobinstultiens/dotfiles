import Quickshell
import QtQuick
import Qs
import "../sidebar"

// Full-screen overlay: background MouseArea dismisses, menu Rectangle is on top.
PanelWindow {
    id: root

    property bool open: false
    signal closeRequested()

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    visible: open || closeTimer.running

    Timer {
        id: closeTimer
        interval: 220
    }

    onOpenChanged: if (!open) closeTimer.start()

    // Transparent full-screen dismiss — TapHandler doesn't block hover events
    // in the panel's MouseAreas, unlike a background MouseArea would.
    TapHandler {
        onTapped: root.closeRequested()
    }

    // Menu panel — declared after MouseArea so it sits on top and captures its own clicks
    Rectangle {
        id: panel
        width: 260
        height: powerButtons.implicitHeight + 16

        anchors.right: parent.right
        anchors.rightMargin: 8

        color: Colors.mantle
        radius: 12

        // Square off the top corners so it looks attached to the bar
        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 12
            color: Colors.mantle
        }

        // Slide down from behind the bar when opening
        y: root.open ? 44 : -(panel.height + 44)
        Behavior on y {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        PowerButtons {
            id: powerButtons
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            onExecuted: root.closeRequested()
        }
    }
}

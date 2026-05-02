import Quickshell.Services.Notifications
import QtQuick
import Qs
import "../.." 1.0

// Individual notification toast. Named 'modelData' so QuickShell Repeater
// auto-injects the Notification object from the ObjectModel without a manual
// property assignment in the delegate.
Item {
    id: root

    required property Notification modelData

    readonly property bool isCritical: modelData.urgency === NotificationUrgency.Critical
    readonly property bool isLow:      modelData.urgency === NotificationUrgency.Low
    // "default" action is invoked by card click — only show named non-default actions as buttons
    readonly property var extraActions: modelData.actions.filter(a => a.identifier !== "default")

    implicitHeight: card.implicitHeight + 4
    clip: false

    // Start off-screen; Component.onCompleted immediately triggers the Behavior to slide in.
    // Initial value assignment never fires Behaviors — only subsequent changes do.
    property real slideX: 360
    transform: Translate { x: root.slideX }
    Behavior on slideX { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

    Component.onCompleted: {
        slideX = 0
        if (!isCritical) dismissTimer.start()
    }

    Timer {
        id: dismissTimer
        interval: modelData.expireTimeout > 0 ? modelData.expireTimeout : 8000
        onTriggered: modelData.expire()
    }

    Rectangle {
        id: card
        width: parent.width
        implicitHeight: inner.implicitHeight + 24
        radius: 10
        color: Colors.mantle

        // Urgency accent bar on left
        Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: 3; radius: 3
            color: root.isCritical ? Colors.red
                 : root.isLow      ? Colors.overlay0
                 : Colors.blue
        }

        // Subtle border
        Rectangle {
            anchors.fill: parent; radius: parent.radius
            color: "transparent"
            border.width: 1
            border.color: root.isCritical
                          ? Qt.rgba(Colors.red.r, Colors.red.g, Colors.red.b, 0.4)
                          : Colors.surface1
        }

        Column {
            id: inner
            anchors {
                left: parent.left; leftMargin: 14
                right: parent.right; rightMargin: 14
                top: parent.top; topMargin: 12
            }
            spacing: 4

            // App header row: icon + name on left, dismiss button on right
            Item {
                width: parent.width
                height: 18

                Row {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    spacing: 6

                    Image {
                        width: 16; height: 16
                        anchors.verticalCenter: parent.verticalCenter
                        source: root.modelData.appIcon !== "" ? "image://icon/" + root.modelData.appIcon : ""
                        visible: root.modelData.appIcon !== ""
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.modelData.appName
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font"
                        color: Colors.overlay1
                    }
                }

                Text {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    text: "󰅙"
                    font.pixelSize: 14
                    font.family: "JetBrainsMono Nerd Font"
                    color: Colors.overlay1
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.modelData.dismiss()
                    }
                }
            }

            // Summary (title)
            Text {
                width: parent.width
                text: root.modelData.summary
                font.pixelSize: 13
                font.weight: Font.Medium
                font.family: "JetBrainsMono Nerd Font"
                color: root.isCritical ? Colors.red : Colors.text
                elide: Text.ElideRight
                visible: text !== ""
            }

            // Body
            Text {
                width: parent.width
                text: root.modelData.body
                font.pixelSize: 12
                font.family: "JetBrainsMono Nerd Font"
                color: Colors.subtext0
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
                visible: text !== ""
            }

            Item { width: 1; height: 4; visible: root.extraActions.length > 0 }

            Row {
                spacing: 6
                visible: root.extraActions.length > 0

                Repeater {
                    model: root.extraActions
                    delegate: ActionButton {}
                }
            }
        }

        // Hover pauses auto-dismiss; click invokes the "default" action (focuses the app).
        // propagateComposedEvents lets dismiss/action button clicks still reach their handlers.
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true
            onEntered: dismissTimer.stop()
            onExited:  if (!root.isCritical) dismissTimer.restart()
            onClicked: (mouse) => {
                const actions = root.modelData.actions
                for (var i = 0; i < actions.length; i++) {
                    if (actions[i].identifier === "default") {
                        actions[i].invoke()
                        break
                    }
                }
                mouse.accepted = false
            }
        }
    }

    component ActionButton: Rectangle {
        required property var modelData  // each NotificationAction

        height: 26
        width: btnLabel.implicitWidth + 16
        radius: 6
        color: Colors.surface0
        border.width: 1
        border.color: Colors.surface1

        Text {
            id: btnLabel
            anchors.centerIn: parent
            text: parent.modelData.text
            font.pixelSize: 11
            font.family: "JetBrainsMono Nerd Font"
            color: Colors.text
        }

        MouseArea {
            anchors.fill: parent
            onClicked: parent.modelData.invoke()
        }
    }
}

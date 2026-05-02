import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import Qs

// Stacked notification toasts anchored to the top-right of the screen,
// appearing below the bar. Each toast auto-dismisses; hover pauses the timer.
PanelWindow {
    id: root

    anchors { top: true; right: true }
    implicitWidth: 360
    // 48 = column topMargin (below bar), 8 = bottom breathing room
    implicitHeight: stack.implicitHeight + 56

    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    // Only show when there are active toasts
    visible: stack.count > 0

    Column {
        id: stack
        anchors { top: parent.top; topMargin: 48; right: parent.right; rightMargin: 8 }
        spacing: 6
        width: 352

        property int count: toastRepeater.count

        Repeater {
            id: toastRepeater
            model: NotificationService.model

            delegate: NotifToast {
                width: stack.width
                // modelData auto-injected into required property Notification modelData
            }
        }
    }
}

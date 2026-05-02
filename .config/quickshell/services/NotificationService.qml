pragma Singleton
import Quickshell.Services.Notifications
import QtQuick

// Wraps QuickShell's NotificationServer — becomes the system notification daemon.
// Make sure no other daemon (mako, dunst) is running alongside qs.
QtObject {
    id: root

    property int unread: 0

    // Exposed model for notification history (NotificationServer.trackedNotifications)
    readonly property var model: server.trackedNotifications

    function clearAll() {
        var notifs = server.trackedNotifications.values
        for (var i = 0; i < notifs.length; i++) {
            notifs[i].dismiss()
        }
        root.unread = 0
    }

    function markRead() {
        root.unread = 0
    }

    property var _impl: Item {

        NotificationServer {
            id: server
            keepOnReload: true
            actionsSupported: true

            onNotification: (notif) => {
                notif.tracked = true
                root.unread++
                console.log("Notification:", notif.appName, "-", notif.summary)
            }
        }
    }
}

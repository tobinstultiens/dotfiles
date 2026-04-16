//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import QtQuick
import "modules/sidebar"
import "modules/bar"

ShellRoot {
    // Shared state for the bar power menu
    QtObject {
        id: pms
        property bool open: false
    }

    // One bar per screen
    Variants {
        model: Quickshell.screens
        Bar {
            required property var modelData
            screen: modelData
            powerMenuState: pms
        }
    }

    // Power menu overlay dropdown
    BarPowerMenu {
        open: pms.open
        onCloseRequested: pms.open = false
    }

    Sidebar {
        id: sidebar
    }

    IpcHandler {
        target: "sidebar"

        function toggle(): void {
            sidebar.open = !sidebar.open
        }

        function show(): void {
            sidebar.open = true
        }

        function hide(): void {
            sidebar.open = false
        }
    }
}

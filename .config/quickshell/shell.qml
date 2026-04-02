//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import "modules/sidebar"
import "modules/bar"

ShellRoot {
    // One bar per screen
    Variants {
        model: Quickshell.screens
        Bar {
            required property var modelData
            screen: modelData
        }
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

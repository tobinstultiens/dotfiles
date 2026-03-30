import Quickshell
import Quickshell.Io
import "." 1.0
import "services"
import "modules/sidebar"

ShellRoot {
    SystemInfo { id: sysInfo; active: sidebar.open }

    Sidebar {
        id: sidebar
        sysInfo: sysInfo
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

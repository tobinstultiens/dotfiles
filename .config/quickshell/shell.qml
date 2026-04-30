//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import QtQuick
import "modules/sidebar"
import "modules/bar"
import "modules/wallpaper"

ShellRoot {
    // Shared state for the bar power menu
    QtObject {
        id: pms
        property bool open: false
    }

    // Shared state for the wallpaper picker
    QtObject {
        id: wps
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

    // One wallpaper renderer per screen — Layer.Background, dual-image crossfade
    Variants {
        model: Quickshell.screens
        WallpaperBackground {
            required property var modelData
            screen: modelData
        }
    }

    WallpaperPicker {
        open: wps.open
        onCloseRequested: wps.open = false
    }

    Sidebar {
        id: sidebar
    }

    IpcHandler {
        target: "wallpaper"

        function toggle(): void { wps.open = !wps.open }
        function show(): void   { wps.open = true }
        function hide(): void   { wps.open = false }
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

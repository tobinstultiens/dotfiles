import Quickshell
import Quickshell.Wayland
import QtQuick
import Qs

// Per-screen crossfade overlay. Covers the hyprpaper "flash to default"
// by showing the incoming wallpaper image on top during the switch.
PanelWindow {
    id: root

    required screen

    // monitorName must be set by the parent to match WallpaperService monitor names
    property string monitorName: ""
    property string pendingPath: ""

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    // Only alive while a transition is in progress
    visible: pendingPath !== "" || img.opacity > 0

    Connections {
        target: WallpaperService
        function onApplyRequested(monitor, path) {
            if (monitor !== root.monitorName) return
            root.pendingPath = path
            img.source = "file://" + path
            // If image is already cached it loads instantly; otherwise wait for Ready
            if (img.status === Image.Ready) fadeIn.start()
        }
    }

    Image {
        id: img
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        opacity: 0

        onStatusChanged: {
            if (status === Image.Ready && root.pendingPath !== "") fadeIn.start()
        }
    }

    SequentialAnimation {
        id: fadeIn
        NumberAnimation {
            target: img; property: "opacity"
            from: 0; to: 1; duration: 120
            easing.type: Easing.OutCubic
        }
        // Hold long enough for hyprpaper to finish the switch (~200ms)
        PauseAnimation { duration: 220 }
        NumberAnimation {
            target: img; property: "opacity"
            from: 1; to: 0; duration: 380
            easing.type: Easing.InCubic
        }
        ScriptAction { script: { root.pendingPath = "" } }
    }
}

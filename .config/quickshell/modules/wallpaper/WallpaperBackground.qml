import Quickshell
import Quickshell.Wayland
import QtQuick
import Qs

// Per-screen wallpaper renderer. Replaces hyprpaper for display.
// Uses two alternating Image components: the inactive one loads the next
// wallpaper asynchronously, then swaps with the visible one only when
// Image.Ready fires — guaranteeing zero blank frames between wallpapers.
PanelWindow {
    id: root

    required screen

    // Matches against WallpaperService.activeWallpapers keys ("DP-1", "DP-2", ...)
    property string monitorName: screen.name

    // Reactive: re-evaluates whenever WallpaperService._wallpapersRev bumps
    property string source: {
        WallpaperService._wallpapersRev
        return WallpaperService.activeWallpapers[monitorName] || ""
    }

    // Which image is currently displayed; the other is the "pending" slot
    property Image currentImg: imgA
    property Image pendingImg: imgB

    onSourceChanged: {
        if (source === "") return
        var fullPath = "file://" + source
        // If already loaded (e.g. rapid re-select), switch immediately
        if (pendingImg.source === fullPath && pendingImg.status === Image.Ready) {
            var tmp = currentImg; currentImg = pendingImg; pendingImg = tmp
        } else {
            pendingImg.source = fullPath
        }
    }

    WlrLayershell.layer: WlrLayer.Background
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: Colors.crust   // shows before first image loads

    Image {
        id: imgA
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true

        opacity: root.currentImg === imgA ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 600; easing.type: Easing.InOutCubic }
        }

        onStatusChanged: {
            if (status === Image.Ready && root.pendingImg === imgA) {
                root.currentImg = imgA
                root.pendingImg = imgB
            }
        }
    }

    Image {
        id: imgB
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true

        opacity: root.currentImg === imgB ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 600; easing.type: Easing.InOutCubic }
        }

        onStatusChanged: {
            if (status === Image.Ready && root.pendingImg === imgB) {
                root.currentImg = imgB
                root.pendingImg = imgA
            }
        }
    }
}

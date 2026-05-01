import Quickshell
import Quickshell.Io
import QtQuick
import Qs

// Full-screen transparent overlay. Click outside the panel to dismiss.
PanelWindow {
    id: root

    property bool open: false
    signal closeRequested()

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    focusable: true
    color: "transparent"

    visible: open || closeTimer.running
    Timer { id: closeTimer; interval: 220 }

    onOpenChanged: {
        if (!open) {
            closeTimer.start()
            restoreWorkspaceProc.running = true
        } else {
            hideWindowsProc.running = true
            panel.forceActiveFocus()
            monitorDetectProc.running = true
        }
    }

    // Background dismiss
    MouseArea {
        anchors.fill: parent
        onClicked: root.closeRequested()
    }

    // Switch to an empty workspace so windows don't obscure the wallpaper preview.
    // Layer-shell surfaces (bar, picker) stay visible across all workspaces.
    Process {
        id: hideWindowsProc
        command: ["hyprctl", "dispatch", "workspace", "empty"]
    }

    Process {
        id: restoreWorkspaceProc
        command: ["hyprctl", "dispatch", "workspace", "previous"]
    }

    // ── Detect active monitor on open ──────────────────────────────────────
    Process {
        id: monitorDetectProc
        property string _buf: ""
        command: ["bash", "-c", "hyprctl activeworkspace -j 2>/dev/null"]
        stdout: SplitParser {
            onRead: line => { monitorDetectProc._buf += line }
        }
        onExited: {
            try {
                var ws = JSON.parse(monitorDetectProc._buf)
                if (ws && ws.monitor) panel.selectedMonitor = ws.monitor
            } catch(e) {}
            monitorDetectProc._buf = ""
            panel.syncCursor()
        }
    }

    Rectangle {
        id: panel

        property string selectedMonitor: WallpaperService.monitors.length > 0
                                             ? WallpaperService.monitors[0] : "DP-1"
        property int    cursorIndex: 0

        function syncCursor() {
            var active = WallpaperService.activeFor(selectedMonitor)
            for (var i = 0; i < WallpaperService.wallpapers.length; i++) {
                if (WallpaperService.wallpapers[i].path === active) {
                    cursorIndex = i
                    return
                }
            }
            cursorIndex = 0
        }

        onSelectedMonitorChanged: syncCursor()

        width: 1000
        height: content.implicitHeight + 32
        anchors.centerIn: parent

        color: Colors.mantle
        radius: 12

        opacity: root.open ? 1.0 : 0.0
        scale:   root.open ? 1.0 : 0.96
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }

        // ── Keyboard navigation ────────────────────────────────────────────
        Keys.onTabPressed: event => {
            var mons = WallpaperService.monitors
            if (mons.length > 1) {
                var idx = mons.indexOf(selectedMonitor)
                selectedMonitor = mons[(idx + 1) % mons.length]
            }
            event.accepted = true
        }
        Keys.onLeftPressed: event => {
            cursorIndex = Math.max(0, cursorIndex - 1)
            previewTimer.restart()
            event.accepted = true
        }
        Keys.onRightPressed: event => {
            cursorIndex = Math.min(WallpaperService.wallpapers.length - 1, cursorIndex + 1)
            previewTimer.restart()
            event.accepted = true
        }
        Keys.onUpPressed: event => {
            cursorIndex = Math.max(0, cursorIndex - 3)
            previewTimer.restart()
            event.accepted = true
        }
        Keys.onDownPressed: event => {
            cursorIndex = Math.min(WallpaperService.wallpapers.length - 1, cursorIndex + 3)
            previewTimer.restart()
            event.accepted = true
        }
        Keys.onReturnPressed: event => {
            var wp = WallpaperService.wallpapers[cursorIndex]
            if (wp) WallpaperService.apply(selectedMonitor, wp.path)
            root.closeRequested()
            event.accepted = true
        }
        Keys.onEscapePressed: event => {
            root.closeRequested()
            event.accepted = true
        }

        // Arrow-key preview: direct apply, no transition overlay (it's live preview)
        Timer {
            id: previewTimer
            interval: 120
            onTriggered: {
                var wp = WallpaperService.wallpapers[panel.cursorIndex]
                if (wp) WallpaperService.apply(panel.selectedMonitor, wp.path)
            }
        }

        Column {
            id: content
            anchors {
                top:    parent.top
                left:   parent.left
                right:  parent.right
                margins: 16
            }
            spacing: 14

            // ── Header row ─────────────────────────────────────────────────
            Row {
                width: parent.width
                height: 34

                Text {
                    text: "WALLPAPER"
                    color: Colors.text
                    font.pixelSize: 13
                    font.bold: true
                    font.letterSpacing: 2
                    font.family: "JetBrainsMono Nerd Font"
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item { width: parent.width - monitorTabs.width - 84; height: 1 }

                Row {
                    id: monitorTabs
                    spacing: 6
                    anchors.verticalCenter: parent.verticalCenter

                    Repeater {
                        model: WallpaperService.monitors
                        Rectangle {
                            width: 58; height: 26; radius: 13
                            color: panel.selectedMonitor === modelData ? Colors.blue : Colors.surface0
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: panel.selectedMonitor === modelData ? Colors.base : Colors.subtext0
                                font.pixelSize: 11
                                font.bold: true
                                font.family: "JetBrainsMono Nerd Font"
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: panel.selectedMonitor = modelData
                            }
                        }
                    }
                }
            }

            // ── Wallpaper grid ─────────────────────────────────────────────
            Grid {
                id: wallpaperGrid
                columns: 3
                spacing: 10
                width: parent.width

                Repeater {
                    model: WallpaperService.wallpapers

                    Rectangle {
                        property bool isActive: WallpaperService.activeFor(panel.selectedMonitor) === modelData.path
                        property bool isCursor: panel.cursorIndex === index

                        width: 316; height: 178
                        radius: 10
                        color: "transparent"
                        border.width: (isActive || isCursor) ? 2 : 1
                        border.color: isCursor ? Colors.mauve : (isActive ? Colors.green : Colors.surface1)

                        Rectangle {
                            anchors { fill: parent; margins: 2 }
                            radius: 8
                            clip: true
                            color: Colors.surface0

                            Image {
                                anchors.fill: parent
                                source: "file://" + modelData.path
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }

                            Rectangle {
                                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                height: 24
                                color: Qt.rgba(Colors.crust.r, Colors.crust.g, Colors.crust.b, 0.82)

                                Text {
                                    anchors {
                                        left: parent.left; right: parent.right
                                        verticalCenter: parent.verticalCenter
                                        margins: 6
                                    }
                                    text: modelData.name
                                    color: Colors.subtext1
                                    font.pixelSize: 10
                                    font.family: "JetBrainsMono Nerd Font"
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                WallpaperService.apply(panel.selectedMonitor, modelData.path)
                                root.closeRequested()
                            }
                        }
                    }
                }
            }
        }
    }
}

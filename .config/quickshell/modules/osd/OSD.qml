import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import Qs

// Floating OSD: shows volume or brightness changes as a transient pill.
// Volume: reacts to PipeWire sink changes automatically.
// Brightness: triggered via `qs ipc call osd brightness <pct>` from hyprland.conf.
PanelWindow {
    id: root

    WlrLayershell.layer: WlrLayer.Overlay

    anchors { bottom: true; left: true; right: true }
    implicitHeight: 80
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    visible: osdItem.opacity > 0

    // ── Public interface (called from IPC handler) ──────────────────────
    function showVolume(val, muted) {
        osdItem.mode    = "volume"
        osdItem.value   = muted ? 0 : val
        osdItem.muted   = muted
        osdItem.opacity = 1
        hideTimer.restart()
    }

    function showBrightness(pct) {
        osdItem.mode    = "brightness"
        osdItem.value   = pct / 100.0
        osdItem.muted   = false
        osdItem.opacity = 1
        hideTimer.restart()
    }

    // ── PipeWire tracking ───────────────────────────────────────────────
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Connections {
        target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
        function onVolumeChanged() {
            var sink = Pipewire.defaultAudioSink
            if (sink) root.showVolume(sink.audio.volume, sink.audio.muted)
        }
        function onMutedChanged() {
            var sink = Pipewire.defaultAudioSink
            if (sink) root.showVolume(sink.audio.volume, sink.audio.muted)
        }
    }

    // ── OSD pill ────────────────────────────────────────────────────────
    Rectangle {
        id: osdItem

        property string mode:  "volume"    // "volume" | "brightness"
        property real   value: 0.0         // 0.0 – 1.0
        property bool   muted: false

        width: 280
        height: 52
        radius: 12
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20

        color: Colors.mantle
        border.width: 1
        border.color: Colors.surface1

        opacity: 0
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        Row {
            anchors.centerIn: parent
            spacing: 12

            // Icon
            Text {
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 18
                font.family: "JetBrainsMono Nerd Font"
                color: Colors.text
                text: {
                    if (osdItem.mode === "brightness") {
                        const b = osdItem.value
                        if (b < 0.15) return "󰛩"
                        if (b < 0.35) return "󰛨"
                        if (b < 0.55) return "󰛧"
                        if (b < 0.75) return "󰛦"
                        return "󰃠"
                    } else {
                        if (osdItem.muted || osdItem.value === 0) return "󰖁"
                        if (osdItem.value < 0.33) return "󰕿"
                        if (osdItem.value < 0.66) return "󰖀"
                        return "󰕾"
                    }
                }
            }

            // Track background
            Rectangle {
                width: 180
                height: 6
                radius: 3
                color: Colors.surface1
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, osdItem.value))
                    height: parent.height
                    radius: parent.radius
                    color: osdItem.mode === "brightness" ? Colors.yellow : Colors.blue
                    Behavior on width {
                        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                    }
                }
            }

            // Percentage label
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: osdItem.muted ? "󰖁" : Math.round(osdItem.value * 100) + "%"
                font.pixelSize: 12
                font.family: "JetBrainsMono Nerd Font"
                color: Colors.subtext1
                width: 36
            }
        }
    }

    Timer {
        id: hideTimer
        interval: 2000
        onTriggered: osdItem.opacity = 0
    }
}

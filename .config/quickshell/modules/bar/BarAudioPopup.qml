import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import Qs
import "../.." 1.0

PanelWindow {
    id: root

    property bool open:   false
    property real popupX: 8
    signal closeRequested()

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    visible: open || closeTimer.running
    onOpenChanged: {
        if (open) AudioService.refresh()
        else closeTimer.start()
    }
    Timer { id: closeTimer; interval: 220 }

    readonly property PwNode sink:   Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    PwObjectTracker { objects: [root.sink, root.source].filter(n => n !== null) }

    MouseArea { anchors.fill: parent; onClicked: root.closeRequested() }

    Rectangle {
        id: panel
        width: 300
        height: content.implicitHeight + 30

        x: Math.max(4, Math.min(root.popupX, root.width - width - 4))
        y: root.open ? 44 : -(height + 44)
        Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        color: Colors.mantle
        radius: 12

        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 12; color: Colors.mantle
        }

        MouseArea { anchors.fill: parent }

        Column {
            id: content
            anchors {
                top: parent.top; topMargin: 16
                left: parent.left; leftMargin: 16
                right: parent.right; rightMargin: 16
            }
            spacing: 10

            // ── Output ─────────────────────────────────────────────────────
            Row {
                width: parent.width
                spacing: 0

                Text {
                    text: "OUTPUT"
                    font.pixelSize: 10; font.letterSpacing: 2
                    font.family: "JetBrainsMono Nerd Font"
                    color: Colors.overlay1
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item { width: parent.width - parent.children[0].width - muteOut.width; height: 1 }

                // Mute toggle
                Text {
                    id: muteOut
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.sink && root.sink.audio && root.sink.audio.muted ? "󰋎" : "󰋋"
                    font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font"
                    color: root.sink && root.sink.audio && root.sink.audio.muted
                           ? Colors.overlay0 : Colors.text
                    MouseArea {
                        anchors.fill: parent
                        onClicked: if (root.sink && root.sink.audio)
                                       root.sink.audio.muted = !root.sink.audio.muted
                    }
                }
            }

            // Sink list
            Repeater {
                model: AudioService.sinks
                DeviceRow {
                    width: content.width
                    label:     modelData.description
                    isDefault: modelData.isDefault
                    onSelected: AudioService.setSink(modelData.name)
                }
            }

            // Volume slider
            Item {
                width: parent.width
                height: 28

                Text {
                    id: volPct
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    text: root.sink && root.sink.audio
                          ? Math.round(root.sink.audio.volume * 100) + "%" : "—%"
                    font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"
                    color: Colors.subtext0
                    width: 32
                }

                // Slider track
                Rectangle {
                    id: track
                    anchors {
                        left: volPct.right; leftMargin: 8
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    height: 4; radius: 2
                    color: Colors.surface1

                    Rectangle {
                        width: root.sink && root.sink.audio
                               ? Math.min(1, root.sink.audio.volume) * parent.width : 0
                        height: parent.height; radius: parent.radius
                        color: Colors.blue
                        Behavior on width { NumberAnimation { duration: 80 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        onClicked: (mouse) => {
                            if (root.sink && root.sink.audio)
                                root.sink.audio.volume = Math.max(0, Math.min(1.5,
                                    mouse.x / track.width))
                        }
                        onPositionChanged: (mouse) => {
                            if (pressed && root.sink && root.sink.audio)
                                root.sink.audio.volume = Math.max(0, Math.min(1.5,
                                    mouse.x / track.width))
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Colors.surface1 }

            // ── Input ──────────────────────────────────────────────────────
            Row {
                width: parent.width

                Text {
                    text: "INPUT"
                    font.pixelSize: 10; font.letterSpacing: 2
                    font.family: "JetBrainsMono Nerd Font"
                    color: Colors.overlay1
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item { width: parent.width - parent.children[0].width - muteIn.width; height: 1 }

                Text {
                    id: muteIn
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.source && root.source.audio && root.source.audio.muted ? "󰍭" : "󰍬"
                    font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font"
                    color: root.source && root.source.audio && root.source.audio.muted
                           ? Colors.overlay0 : Colors.text
                    MouseArea {
                        anchors.fill: parent
                        onClicked: if (root.source && root.source.audio)
                                       root.source.audio.muted = !root.source.audio.muted
                    }
                }
            }

            Repeater {
                model: AudioService.sources
                DeviceRow {
                    width: content.width
                    label:     modelData.description
                    isDefault: modelData.isDefault
                    onSelected: AudioService.setSource(modelData.name)
                }
            }

            // Loading indicator
            Text {
                visible: AudioService.loading
                text: "Loading…"
                font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"
                color: Colors.overlay0
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    // Radio-button-style device row
    component DeviceRow: Item {
        property string label:     ""
        property bool   isDefault: false
        signal selected

        implicitHeight: 28

        Rectangle {
            width: 14; height: 14; radius: 7
            anchors.verticalCenter: parent.verticalCenter
            color: "transparent"
            border.width: 1.5
            border.color: parent.isDefault ? Colors.blue : Colors.surface2

            Rectangle {
                width: 8; height: 8; radius: 4
                anchors.centerIn: parent
                color: Colors.blue
                visible: parent.parent.isDefault
            }
        }

        Text {
            anchors {
                left: parent.left; leftMargin: 22
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            text: parent.label
            font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"
            color: parent.isDefault ? Colors.text : Colors.subtext0
            elide: Text.ElideRight
        }

        MouseArea {
            anchors.fill: parent
            onClicked: parent.selected()
        }
    }
}

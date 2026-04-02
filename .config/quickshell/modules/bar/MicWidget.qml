import Quickshell.Services.Pipewire
import QtQuick
import Qs

Item {
    id: root
    implicitHeight: parent.height
    implicitWidth: pill.implicitWidth

    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool   muted:  source && source.audio ? source.audio.muted  : false
    readonly property real   volume: source && source.audio ? (source.audio.volume || 0.0) : 0.0

    Rectangle {
        id: pill
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: lbl.implicitWidth + 20
        height: Colors.pillHeight
        radius: 8
        color: Colors.surface0

        Text {
            id: lbl
            anchors.centerIn: parent
            text: Math.round(root.volume * 100) + "%  " + (root.muted ? "󰍭" : "󰍬")
            font.pixelSize: 13
            font.family: "JetBrainsMono Nerd Font"
            color: root.muted ? Colors.overlay1 : Colors.text
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (root.source && root.source.audio)
                    root.source.audio.muted = !root.source.audio.muted
            }
            onWheel: e => {
                if (root.source && root.source.audio) {
                    const delta = e.angleDelta.y > 0 ? 0.05 : -0.05
                    root.source.audio.volume = Math.max(0, Math.min(1.5, root.source.audio.volume + delta))
                }
            }
        }
    }
}

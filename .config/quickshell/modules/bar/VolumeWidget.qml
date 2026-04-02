import Quickshell.Services.Pipewire
import QtQuick
import Qs

Item {
    id: root
    implicitHeight: parent.height
    implicitWidth: pill.implicitWidth

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool   muted:  sink && sink.audio ? sink.audio.muted  : false
    readonly property real   volume: sink && sink.audio ? (sink.audio.volume || 0.0) : 0.0

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
            text: Math.round(root.volume * 100) + "%  " + (root.muted ? "󰋎" : "󰋋")
            font.pixelSize: 13
            font.family: "JetBrainsMono Nerd Font"
            color: root.muted ? Colors.overlay1 : Colors.text
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (root.sink && root.sink.audio)
                    root.sink.audio.muted = !root.sink.audio.muted
            }
            onWheel: e => {
                if (root.sink && root.sink.audio) {
                    const delta = e.angleDelta.y > 0 ? 0.05 : -0.05
                    root.sink.audio.volume = Math.max(0, Math.min(1.5, root.sink.audio.volume + delta))
                }
            }
        }
    }
}

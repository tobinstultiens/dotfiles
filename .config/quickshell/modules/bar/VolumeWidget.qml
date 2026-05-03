import Quickshell.Services.Pipewire
import QtQuick
import Qs

Item {
    id: root
    implicitHeight: parent.height
    implicitWidth: pill.implicitWidth

    signal popupRequested(real screenX)

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool   muted:  sink && sink.audio ? sink.audio.muted  : false
    readonly property real   volume: sink && sink.audio ? sink.audio.volume : 0.0

    PwObjectTracker { objects: sink ? [sink] : [] }

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
            onClicked: root.popupRequested(root.mapToItem(null, 0, 0).x)
            onWheel: e => {
                if (root.sink && root.sink.audio) {
                    const delta = e.angleDelta.y > 0 ? 0.05 : -0.05
                    root.sink.audio.volume = Math.max(0, Math.min(1.5, root.sink.audio.volume + delta))
                }
            }
        }
    }
}

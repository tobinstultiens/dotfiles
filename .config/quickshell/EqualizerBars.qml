import QtQuick
import Qs

Row {
    id: eqRoot
    property bool playing: false
    property color barColor: Colors.overlay1

    spacing: 2
    visible: eqRoot.playing

    Repeater {
        model: 3
        delegate: Item {
            id: barItem
            required property int modelData
            property real maxH: [9, 12, 7][modelData]
            property int animDur: [280, 350, 310][modelData]
            width: 2
            height: 14

            Rectangle {
                id: eqBar
                width: 2
                anchors.bottom: parent.bottom
                radius: 1
                color: eqRoot.barColor
                height: barH
                property real barH: 3

                SequentialAnimation {
                    running: eqRoot.playing
                    loops: Animation.Infinite
                    onRunningChanged: if (!running) eqBar.barH = 3
                    NumberAnimation { target: eqBar; property: "barH"; to: barItem.maxH; duration: barItem.animDur; easing.type: Easing.InOutSine }
                    NumberAnimation { target: eqBar; property: "barH"; to: 3; duration: barItem.animDur; easing.type: Easing.InOutSine }
                }
            }
        }
    }
}

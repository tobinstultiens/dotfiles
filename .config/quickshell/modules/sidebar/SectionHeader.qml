import QtQuick
import "../.." 1.0

Item {
    id: root
    required property string label
    property color accent: Colors.blue
    implicitHeight: 20

    Rectangle {
        id: accentBar
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: 14
        radius: 1.5
        color: root.accent
    }

    Text {
        id: labelText
        anchors {
            left: accentBar.right
            leftMargin: 7
            verticalCenter: parent.verticalCenter
        }
        text: root.label
        font.pixelSize: 10
        font.weight: Font.Bold
        font.letterSpacing: 1.5
        color: Colors.subtext1
    }

    Rectangle {
        anchors {
            left: labelText.right
            leftMargin: 8
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        height: 1
        color: Colors.surface1
    }
}

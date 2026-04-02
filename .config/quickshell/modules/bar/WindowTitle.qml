import Quickshell.Hyprland
import QtQuick
import Qs

Item {
    id: root
    implicitHeight: parent.height

    function rewriteTitle(t) {
        if (!t) return ""
        const rules = [
            [/^(.*) — Mozilla Firefox$/, "🌎 $1"],
            [/^(.*) - Youtube$/,         " $1"],
            [/^(.*) - vim$/,             " $1"],
            [/^(.*) - sh$/,              " [$1]"],
            [/^(.*) - st$/,              "> [$1]"],
            [/^(.*) - tmux$/,            "> [$1]"],
        ]
        for (const [pattern, replacement] of rules) {
            if (pattern.test(t)) return t.replace(pattern, replacement)
        }
        return t
    }

    Rectangle {
        anchors.centerIn: parent
        height: Colors.pillHeight
        width: titleText.implicitWidth + 20
        radius: 8
        color: Colors.surface0
        visible: titleText.text !== ""

        Text {
            id: titleText
            anchors.centerIn: parent
            text: root.rewriteTitle(Hyprland.activeToplevel ? Hyprland.activeToplevel.title : "")
            font.pixelSize: 13
            font.family: "JetBrainsMono Nerd Font"
            color: Colors.text
        }
    }
}

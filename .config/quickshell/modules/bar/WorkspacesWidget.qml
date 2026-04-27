import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import Qs

Item {
    id: root
    required property var barScreen
    implicitHeight: parent.height
    implicitWidth: row.implicitWidth

    function appIcon(cls) {
        const c = (cls || "").toLowerCase()
        if (c.includes("code"))                return "\u{F0A1E}"
        if (c.includes("rider"))               return ""
        if (c.includes("nvim") || c.includes("vim")) return ""
        if (c.includes("tmux") || c === "sh" || c === "bash" || c === "zsh") return ""
        if (c.includes("st-") || c === "st")   return ""
        if (c.includes("discord") || c.includes("vesktop")) return ""
        if (c.includes("whatsdesk"))           return ""
        if (c.includes("steam"))               return ""
        if (c.includes("hearthstone"))         return "\u{F0EB7}"
        if (c.includes("thunderbird"))         return ""
        if (c.includes("spotify"))             return ""
        if (c.includes("jellyfin"))            return ""
        if (c.includes("firefox"))             return ""
        return ""
    }

    function wsColor(id) {
        const palette = [Colors.blue, Colors.mauve, Colors.green, Colors.peach,
                         Colors.red, Colors.yellow, Colors.teal, Colors.sapphire,
                         Colors.lavender, Colors.pink]
        return palette[(id - 1) % palette.length]
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Repeater {
            model: Hyprland.workspaces

            delegate: Rectangle {
                required property HyprlandWorkspace modelData
                property HyprlandWorkspace ws: modelData

                visible: ws.monitor && ws.monitor.name === root.barScreen.name

                height: Colors.pillHeight
                implicitWidth: Math.max(36, iconRow.implicitWidth + 20) + focusBoost
                radius: 8
                color: ws.focused ? Colors.surface1 : Colors.surface0

                property real focusBoost: ws.focused ? 14 : 0
                Behavior on focusBoost { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 120 } }

                // Window icons, centered in the pill
                Row {
                    id: iconRow
                    anchors.centerIn: parent
                    spacing: 3

                    Repeater {
                        id: iconRepeater
                        model: Hyprland.toplevels.values.filter(
                                   t => t.workspace && t.workspace.id === ws.id)
                        delegate: Item {
                            required property HyprlandToplevel modelData

                            property string appClass: (modelData.lastIpcObject && modelData.lastIpcObject["class"])
                                                      || modelData.appId || ""
                            property string iconSrc: {
                                const p = Quickshell.iconPath(appClass, true)
                                if (p !== "") return p
                                return Quickshell.iconPath(appClass.toLowerCase(), true)
                            }

                            width: 16
                            height: 16

                            IconImage {
                                id: iconImg
                                anchors.fill: parent
                                implicitSize: 16
                                source: parent.iconSrc
                                visible: parent.iconSrc !== "" && status === Image.Ready
                            }

                            Text {
                                anchors.centerIn: parent
                                text: root.appIcon(parent.appClass)
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                                color: Colors.text
                                visible: parent.iconSrc === "" || iconImg.status !== Image.Ready
                            }
                        }
                    }
                }

                // Colored accent bar — unique per workspace ID, dims when unfocused
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 4
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 12
                    height: 2
                    radius: 1
                    color: root.wsColor(ws.id)
                    opacity: ws.focused ? 1.0 : 0.35
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: ws.activate()
                }
            }
        }
    }
}

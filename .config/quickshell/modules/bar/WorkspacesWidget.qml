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
        if (c.includes("rider"))               return "\uE88F"
        if (c.includes("nvim") || c.includes("vim")) return "\uE6AE"
        if (c.includes("tmux") || c === "sh" || c === "bash" || c === "zsh") return "\uE6AE"
        if (c.includes("st-") || c === "st")   return "\uE795"
        if (c.includes("discord") || c.includes("vesktop")) return "\uF1FF"
        if (c.includes("whatsdesk"))           return "\uF232"
        if (c.includes("steam"))               return "\uF1B6"
        if (c.includes("hearthstone"))         return "\u{F0EB7}"
        if (c.includes("thunderbird"))         return "\uF370"
        if (c.includes("spotify"))             return "\uF1BC"
        if (c.includes("jellyfin"))            return "\uF36E"
        if (c.includes("firefox"))             return "\uF269"
        return "\uF2D0"
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

                // Only show workspaces on this screen's monitor
                visible: ws.monitor && ws.monitor.name === root.barScreen.name

                height: Colors.pillHeight
                implicitWidth: Math.max(32, wsContent.implicitWidth + 16)
                radius: 8
                color: ws.focused ? Colors.surface1 : Colors.surface0

                Behavior on color { ColorAnimation { duration: 120 } }

                // Workspace number (top) + window icons (bottom)
                Column {
                    id: wsContent
                    anchors.centerIn: parent
                    spacing: 2

                    Text {
                        text: ws.id
                        font.pixelSize: 10
                        color: ws.focused ? Colors.text : Colors.overlay1
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    // Window icons row — hidden when workspace is empty
                    Row {
                        id: iconRow
                        spacing: 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: iconRepeater.count > 0

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
                                    color: Colors.subtext0
                                    visible: parent.iconSrc === "" || iconImg.status !== Image.Ready
                                }
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: ws.activate()
                }
            }
        }
    }
}

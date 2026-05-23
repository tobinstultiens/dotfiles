import Quickshell.Services.Mpris
import QtQuick
import Qt5Compat.GraphicalEffects
import Qs
import "../.." 1.0

Item {
    id: root
    implicitHeight: parent.height
    implicitWidth: visible ? pill.implicitWidth : 0
    visible: player !== null

    readonly property MprisPlayer player: {
        const players = Mpris.players.values
        const isSpotify = p => (p.identity || "").toLowerCase().includes("spotify")
        const spotify = players.find(isSpotify)
        if (spotify && spotify.isPlaying) return spotify
        for (let i = 0; i < players.length; i++) {
            if (players[i].isPlaying) return players[i]
        }
        if (spotify && spotify.trackTitle) return spotify
        return players.length > 0 ? players[0] : null
    }

    signal popupToggled

    readonly property bool playing: player !== null && player.isPlaying
    readonly property bool isSpotify: player !== null
        && (player.identity || "").toLowerCase().includes("spotify")

    function truncate(str, max) {
        return str && str.length > max ? str.slice(0, max - 1) + "…" : (str || "")
    }

    function trackText(p) {
        if (!p) return ""
        const artist = p.trackArtist || ""
        const title  = p.trackTitle  || ""
        const raw    = artist && title ? artist + " – " + title : title || artist
        return root.truncate(raw, 32)
    }

    // Bar media pill — album art + controls + track text + equalizer
    Rectangle {
        id: pill
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: row.implicitWidth + 18
        height: Colors.pillHeight
        radius: 10
        color: Colors.surface0
        clip: true
        border.width: 1
        border.color: root.playing && root.isSpotify
                      ? Qt.rgba(0x1D/255, 0xB9/255, 0x54/255, 0.7)
                      : "transparent"

        Behavior on border.color  { ColorAnimation  { duration: 300 } }
        Behavior on implicitWidth { NumberAnimation { duration: 200 } }

        // Background click toggles the popup; controls consume their own clicks first
        MouseArea {
            anchors.fill: parent
            onClicked: root.popupToggled()
        }

        // Subtle album art fill behind text
        Image {
            anchors.fill: parent
            source: root.player && root.player.trackArtUrl ? root.player.trackArtUrl : ""
            fillMode: Image.PreserveAspectCrop
            opacity: 0.12
            asynchronous: true
        }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 8

            // Circular album art + radial equalizer ring
            Item {
                id: artWrap
                width: 34; height: 34
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: 16
                    delegate: Item {
                        anchors.centerIn: parent
                        width: 0; height: 0
                        rotation: index * 22.5

                        Rectangle {
                            id: bar
                            property real barH: 1
                            width: 2
                            height: barH
                            x: -1
                            y: -(12 + barH)
                            radius: 1
                            color: root.playing && root.isSpotify ? "#1DB954" : Colors.mauve
                            opacity: root.playing ? 1.0 : 0.25
                            Behavior on opacity { NumberAnimation { duration: 200 } }

                            SequentialAnimation on barH {
                                running: root.playing
                                loops: Animation.Infinite
                                onRunningChanged: if (!running) bar.barH = 1
                                NumberAnimation {
                                    to: 1 + (index % 3) * 1.5
                                    duration: 260 + (index * 37) % 180
                                    easing.type: Easing.InOutSine
                                }
                                NumberAnimation {
                                    to: 4 - (index % 2)
                                    duration: 260 + ((index + 5) * 43) % 180
                                    easing.type: Easing.InOutSine
                                }
                            }
                        }
                    }
                }

                Item {
                    anchors.centerIn: parent
                    width: 22; height: 22

                    Rectangle {
                        anchors.fill: parent
                        radius: 11
                        color: Colors.surface1
                    }

                    Image {
                        id: pillArtImg
                        anchors.fill: parent
                        source: root.player ? (root.player.trackArtUrl || "") : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: root.player !== null && root.player.trackArtUrl !== ""
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: 22; height: 22
                                radius: 11
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: !root.player || root.player.trackArtUrl === ""
                        text: "󰝚"
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font"
                        color: Colors.overlay0
                    }
                }
            }

            // Prev
            BarCtrl {
                icon: "󰒮"
                size: 14
                canUse: root.player && root.player.canGoPrevious
                textColor: Colors.subtext1
                onTap: if (root.player) root.player.previous()
            }

            // Play / Pause
            BarCtrl {
                icon: root.playing ? "󰏤" : "󰐊"
                size: 15
                canUse: root.player && root.player.canTogglePlaying
                textColor: root.playing && root.isSpotify ? "#1DB954" : Colors.text
                onTap: if (root.player) root.player.togglePlaying()
            }

            // Next
            BarCtrl {
                icon: "󰒭"
                size: 14
                canUse: root.player && root.player.canGoNext
                textColor: Colors.subtext1
                onTap: if (root.player) root.player.next()
            }

            // Track text
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.trackText(root.player)
                font.pixelSize: 12
                font.family: "JetBrainsMono Nerd Font"
                color: Colors.text
            }

        }
    }

    // Inline icon button used for bar controls
    component BarCtrl: Item {
        property string icon: ""
        property real   size: 14
        property bool   canUse: true
        property color  textColor: Colors.text
        signal tap

        width: size + 6; height: size + 6
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        opacity: canUse ? 1.0 : 0.35

        Text {
            anchors.centerIn: parent
            text: parent.icon
            font.pixelSize: parent.size
            font.family: "JetBrainsMono Nerd Font"
            color: parent.textColor
        }

        MouseArea {
            anchors.fill: parent
            onClicked: parent.tap()
        }
    }
}

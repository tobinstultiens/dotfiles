import Quickshell.Services.Mpris
import QtQuick
import Qs
import "../.." 1.0

Item {
    id: root

    readonly property MprisPlayer player: {
        const players = Mpris.players.values
        let spotify = null, spotifyPlaying = null, anyPlaying = null
        for (let i = 0; i < players.length; i++) {
            const p = players[i]
            const isSpt = p.identity && p.identity.toLowerCase().includes("spotify")
            if (isSpt) {
                if (!spotify) spotify = p
                if (p.isPlaying) spotifyPlaying = p
            } else if (p.isPlaying && !anyPlaying) {
                anyPlaying = p
            }
        }
        if (spotifyPlaying) return spotifyPlaying
        if (anyPlaying)     return anyPlaying
        if (spotify)        return spotify
        return players.length > 0 ? players[0] : null
    }

    readonly property bool isPlaying: player !== null && player.isPlaying
    readonly property bool isSpotify: player !== null
        && (player.identity || "").toLowerCase().includes("spotify")
    readonly property string artUrl: player ? (player.trackArtUrl || "") : ""

    implicitHeight: visible ? col.implicitHeight : 0
    visible: root.player !== null

    Column {
        id: col
        width: parent.width
        spacing: 0

        SectionHeader { width: parent.width; label: "MEDIA"; accent: Colors.mauve }

        // ── Main card ───────────────────────────────────────────────────────
        Rectangle {
            width: parent.width
            implicitHeight: cardContent.implicitHeight
            color: Colors.surface0
            radius: 10
            clip: true

            // Full-bleed album art background at low opacity
            Image {
                anchors.fill: parent
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                opacity: 0.18
                asynchronous: true
            }

            // Horizontal gradient: transparent on left → surface0 on right
            // Makes the art bleed in from the left while right stays readable
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0;  color: "transparent" }
                    GradientStop { position: 0.38; color: Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.72) }
                    GradientStop { position: 0.55; color: Colors.surface0 }
                    GradientStop { position: 1.0;  color: Colors.surface0 }
                }
            }

            // Spotify active border
            Rectangle {
                anchors.fill: parent; radius: parent.radius
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(0x1D/255, 0xB9/255, 0x54/255, root.isSpotify && root.isPlaying ? 0.5 : 0)
                Behavior on border.color { ColorAnimation { duration: 500 } }
            }

            Column {
                id: cardContent
                width: parent.width

                // ── Top: art + metadata ──────────────────────────────────────
                Row {
                    width: parent.width
                    spacing: 12
                    padding: 14

                    // Album art square — explicit, at full opacity
                    Rectangle {
                        width: 72; height: 72
                        radius: 8
                        color: Colors.surface1
                        clip: true
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            anchors.fill: parent
                            source: root.artUrl
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }

                        // Placeholder when no art
                        Text {
                            anchors.centerIn: parent
                            visible: root.artUrl === ""
                            text: "󰝚"
                            font.pixelSize: 28
                            font.family: "JetBrainsMono Nerd Font"
                            color: Colors.overlay0
                        }
                    }

                    // Metadata column
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 72 - 12 - 28  // minus art, spacing, padding
                        spacing: 3

                        // Player name + equalizer
                        Row {
                            spacing: 6
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.player ? (root.player.identity || "") : ""
                                font.pixelSize: 10
                                font.family: "JetBrainsMono Nerd Font"
                                color: Colors.overlay1
                            }
                            CavaWidget {
                                anchors.verticalCenter: parent.verticalCenter
                                bars: 10
                                barColor: root.isSpotify ? "#1DB954" : Colors.mauve
                                playing: root.isPlaying
                            }
                        }

                        // Title
                        Text {
                            width: parent.width
                            text: root.player ? (root.player.trackTitle || "Unknown") : ""
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            font.family: "JetBrainsMono Nerd Font"
                            color: Colors.text
                            elide: Text.ElideRight
                        }

                        // Artist
                        Text {
                            width: parent.width
                            text: root.player ? (root.player.trackArtist || "") : ""
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                            color: Colors.subtext0
                            elide: Text.ElideRight
                        }
                    }
                }

                // ── Progress bar ─────────────────────────────────────────────
                Item {
                    width: parent.width - 28
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 14
                    visible: root.player !== null
                        && root.player.lengthSupported
                        && root.player.length > 0

                    Rectangle {
                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                        height: 3; radius: 2
                        color: Colors.surface1

                        Rectangle {
                            width: (root.player && root.player.length > 0)
                                   ? parent.width * Math.min(1, root.player.position / root.player.length)
                                   : 0
                            height: parent.height; radius: parent.radius
                            color: root.isSpotify ? "#1DB954" : Colors.mauve
                            Behavior on width { NumberAnimation { duration: 1000; easing.type: Easing.Linear } }
                        }
                    }
                }

                // ── Controls ─────────────────────────────────────────────────
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8
                    bottomPadding: 12

                    MediaBtn {
                        icon: "󰒮"
                        active: root.player && root.player.canGoPrevious
                        onTap: if (root.player) root.player.previous()
                    }
                    MediaBtn {
                        icon: root.isPlaying ? "󰏤" : "󰐊"
                        active: root.player && root.player.canTogglePlaying
                        onTap: if (root.player) root.player.togglePlaying()
                        large: true
                        accent: root.isSpotify && root.isPlaying
                    }
                    MediaBtn {
                        icon: "󰒭"
                        active: root.player && root.player.canGoNext
                        onTap: if (root.player) root.player.next()
                    }
                }
            }
        }
    }

    component MediaBtn: Item {
        property string icon:   ""
        property bool   active: true
        property bool   large:  false
        property bool   accent: false
        signal tap

        width: large ? 44 : 36
        height: large ? 44 : 36

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: accent ? Qt.rgba(0x1D/255, 0xB9/255, 0x54/255, 0.18)
                          : (ma.containsMouse ? Colors.surface1 : "transparent")
            Behavior on color { ColorAnimation { duration: 100 } }
        }

        Text {
            anchors.centerIn: parent
            text: parent.icon
            font.pixelSize: parent.large ? 22 : 17
            font.family: "JetBrainsMono Nerd Font"
            color: !parent.active   ? Colors.overlay0
                 : parent.accent    ? "#1DB954"
                 : parent.large     ? Colors.text
                 : Colors.subtext1
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            onClicked: parent.tap()
        }
    }
}

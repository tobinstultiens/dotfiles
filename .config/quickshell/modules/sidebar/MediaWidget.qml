import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import Qs
import "../.." 1.0

Item {
    id: root

    readonly property MprisPlayer player: {
        const players = Mpris.players.values
        let spotify = null
        let spotifyPlaying = null
        let anyPlaying = null
        for (let i = 0; i < players.length; i++) {
            const p = players[i]
            const isSpotify = p.identity && p.identity.toLowerCase().includes("spotify")
            if (isSpotify) {
                if (!spotify) spotify = p
                if (p.isPlaying) spotifyPlaying = p
            } else if (p.isPlaying && !anyPlaying) {
                anyPlaying = p
            }
        }
        // Priority: Spotify playing → any playing → Spotify paused → any player
        if (spotifyPlaying) return spotifyPlaying
        if (anyPlaying) return anyPlaying
        if (spotify) return spotify
        return players.length > 0 ? players[0] : null
    }

    readonly property bool isSpotifyPlaying: {
        const p = root.player
        return p !== null && p.isPlaying
            && p.identity && p.identity.toLowerCase().includes("spotify")
    }

    implicitHeight: visible ? col.implicitHeight : 0
    visible: root.player !== null

    Column {
        id: col
        width: parent.width
        spacing: 0

        SectionHeader {
            width: parent.width
            label: "MEDIA"
            accent: Colors.mauve
        }

        Rectangle {
            width: parent.width
            implicitHeight: inner.implicitHeight + 20
            color: Colors.surface0
            radius: 8
            clip: true
            border.width: 1
            border.color: Qt.rgba(0x1D/255.0, 0xB9/255.0, 0x54/255.0, borderOpacity)
            property real borderOpacity: root.isSpotifyPlaying ? 0.55 : 0
            Behavior on borderOpacity { NumberAnimation { duration: 500 } }

            // Album art as subtle background
            Image {
                visible: root.player && root.player.trackArtUrl !== ""
                anchors.fill: parent
                source: root.player ? (root.player.trackArtUrl || "") : ""
                fillMode: Image.PreserveAspectCrop
                opacity: 0.15
            }

            Column {
                id: inner
                anchors {
                    left: parent.left; right: parent.right
                    leftMargin: 14; rightMargin: 14
                    top: parent.top; topMargin: 14
                }
                spacing: 4

                // Player name + animated equalizer when playing
                Row {
                    spacing: 6

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.player ? (root.player.identity || "") : ""
                        font.pixelSize: 10
                        color: Colors.overlay1
                    }

                    EqualizerBars {
                        anchors.verticalCenter: parent.verticalCenter
                        playing: root.player !== null && root.player.isPlaying
                    }
                }

                // Track title
                Text {
                    width: parent.width
                    text: root.player ? (root.player.trackTitle || "Unknown") : ""
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: Colors.text
                    elide: Text.ElideRight
                }

                // Artist
                Text {
                    width: parent.width
                    text: root.player ? (root.player.trackArtist || "") : ""
                    font.pixelSize: 12
                    color: Colors.subtext0
                    elide: Text.ElideRight
                    bottomPadding: 4
                }

                // Progress bar
                Item {
                    width: parent.width
                    height: 16
                    visible: root.player !== null && root.player.lengthSupported && root.player.length > 0

                    Rectangle {
                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                        height: 4; radius: 2; color: Colors.surface1

                        Rectangle {
                            width: (root.player && root.player.length > 0)
                                   ? parent.width * Math.min(1, root.player.position / root.player.length)
                                   : 0
                            height: parent.height; radius: parent.radius
                            color: Colors.green
                            Behavior on width { NumberAnimation { duration: 1000; easing.type: Easing.Linear } }
                        }
                    }
                }

                // Controls
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 16
                    bottomPadding: 4

                    MediaBtn {
                        icon: "󰒮"
                        active: root.player && root.player.canGoPrevious
                        onTap: if (root.player) root.player.previous()
                    }
                    MediaBtn {
                        icon: root.player && root.player.isPlaying ? "󰏤" : "󰐊"
                        active: root.player && root.player.canTogglePlaying
                        onTap: if (root.player) root.player.togglePlaying()
                        large: true
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
        signal tap

        width: large ? 40 : 34
        height: large ? 40 : 34

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: ma.containsMouse ? Colors.surface1 : "transparent"
            Behavior on color { ColorAnimation { duration: 100 } }
        }

        Text {
            anchors.centerIn: parent
            text: parent.icon
            font.pixelSize: parent.large ? 22 : 18
            color: parent.active ? Colors.text : Colors.overlay0
            font.family: "JetBrainsMono Nerd Font"
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            onClicked: parent.tap()
        }
    }
}

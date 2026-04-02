import Quickshell.Services.Mpris
import QtQuick
import Qs

Item {
    id: root
    implicitHeight: parent.height
    implicitWidth: visible ? pill.implicitWidth : 0
    visible: player !== null

    readonly property MprisPlayer player: {
        const players = Mpris.players.values
        const isSpotify = p => (p.identity || "").toLowerCase().includes("spotify")
        const spotify = players.find(isSpotify)
        // Prefer Spotify when it's playing
        if (spotify && spotify.isPlaying) return spotify
        // Otherwise pick the first playing player
        for (let i = 0; i < players.length; i++) {
            if (players[i].isPlaying) return players[i]
        }
        // Nothing playing: prefer Spotify if it has track info, then any player
        if (spotify && spotify.trackTitle) return spotify
        return players.length > 0 ? players[0] : null
    }

    readonly property bool playing: player !== null && player.isPlaying

    function truncate(str, max) {
        return str && str.length > max ? str.slice(0, max - 1) + "…" : (str || "")
    }

    function playerIcon(p) {
        if (!p) return "🎜"
        return (p.identity || "").toLowerCase().includes("spotify") ? "" : "🎜"
    }

    function trackText(p) {
        if (!p) return ""
        const artist = p.trackArtist || ""
        const title  = p.trackTitle  || ""
        const raw    = artist && title ? artist + " - " + title : title || artist
        return root.truncate(raw, 40)
    }

    Rectangle {
        id: pill
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: label.implicitWidth + 20
        height: Colors.pillHeight
        radius: 10
        color: root.playing ? "#1DB954" : Colors.surface0

        Behavior on color { ColorAnimation { duration: 200 } }

        Text {
            id: label
            anchors.centerIn: parent
            text: root.playerIcon(root.player) + "  " + root.trackText(root.player)
            font.pixelSize: 13
            font.family: "JetBrainsMono Nerd Font"
            color: root.playing ? "#1f1f28" : Colors.text
        }
    }
}

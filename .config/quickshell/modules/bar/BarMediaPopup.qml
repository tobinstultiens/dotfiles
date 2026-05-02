import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Shapes
import Qs
import "../.." 1.0

// Media popup — slides down from the bar on the left side.
// Inspired by caelestia-dots/shell: circular progress arc around album art.
PanelWindow {
    id: root

    property bool   open: false
    property real   popupX: 8
    property string selectedIdentity: ""   // "" = auto-pick the best player
    signal closeRequested()

    readonly property MprisPlayer player: {
        const players = Mpris.players.values
        // Honour manual selection if that player is still available
        if (root.selectedIdentity !== "") {
            const sel = players.find(p => (p.identity || "") === root.selectedIdentity)
            if (sel) return sel
        }
        // Auto-select: Spotify playing → any playing → Spotify paused → first
        const isSpotify = p => (p.identity || "").toLowerCase().includes("spotify")
        const spotify = players.find(isSpotify)
        if (spotify && spotify.isPlaying) return spotify
        for (let i = 0; i < players.length; i++) {
            if (players[i].isPlaying) return players[i]
        }
        if (spotify && spotify.trackTitle) return spotify
        return players.length > 0 ? players[0] : null
    }

    readonly property bool isSpotify: player !== null
        && (player.identity || "").toLowerCase().includes("spotify")
    readonly property string artUrl:   player ? (player.trackArtUrl || "") : ""
    readonly property real   progress: {
        if (!player || !player.lengthSupported || player.length <= 0) return 0
        return Math.min(1, player.position / player.length)
    }

    function formatTime(secs) {
        if (!secs || secs <= 0) return "0:00"
        const m = Math.floor(secs / 60)
        const s = Math.floor(secs % 60)
        return m + ":" + (s < 10 ? "0" + s : s)
    }

    // Tick position forward while popup is open and player is playing
    Timer {
        interval: 1000
        running: root.open && root.player !== null && root.player.isPlaying
        repeat: true
        onTriggered: if (root.player) root.player.positionChanged()
    }

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    visible: open || closeTimer.running
    Timer { id: closeTimer; interval: 220 }
    onOpenChanged: if (!open) closeTimer.start()

    MouseArea {
        anchors.fill: parent
        onClicked: root.closeRequested()
    }

    Rectangle {
        id: panel
        width: 284
        height: content.implicitHeight + 30   // 16 top + 14 bottom padding

        // Align left edge with the media widget's screen position
        x: root.popupX
        y: root.open ? 44 : -(height + 44)
        Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        color: Colors.mantle
        radius: 12

        // Square off the top corners so it looks attached to the bar
        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 12
            color: Colors.mantle
        }

        MouseArea { anchors.fill: parent }

        Column {
            id: content
            anchors {
                top: parent.top; topMargin: 16
                left: parent.left; leftMargin: 16
                right: parent.right; rightMargin: 16
            }
            spacing: 0

            // ── Player name + equalizer ─────────────────────────────────
            Row {
                spacing: 6
                anchors.horizontalCenter: parent.horizontalCenter

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.player ? (root.player.identity || "") : ""
                    font.pixelSize: 11
                    font.family: "JetBrainsMono Nerd Font"
                    color: Colors.overlay1
                }

                EqualizerBars {
                    anchors.verticalCenter: parent.verticalCenter
                    playing: root.player !== null && root.player.isPlaying
                    barColor: root.isSpotify ? "#1DB954" : Colors.mauve
                }
            }

            Item { width: 1; height: 10 }

            // ── Album art with circular progress ring ───────────────────
            // Art: 150×150, ring radius: 85 (art half 75 + 8 gap + 2 stroke-half)
            // Container: 174×174  (2 × (85+2) = 174)
            Item {
                id: artContainer
                width: 174; height: 174
                anchors.horizontalCenter: parent.horizontalCenter

                // Background ring (full circle)
                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeColor: Colors.surface1
                        strokeWidth: 4
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        PathAngleArc {
                            centerX: 87; centerY: 87
                            radiusX: 85; radiusY: 85
                            startAngle: -90; sweepAngle: 360
                        }
                    }
                }

                // Progress arc (caelestia-style)
                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    visible: root.progress > 0.001
                    ShapePath {
                        strokeColor: root.isSpotify ? "#1DB954" : Colors.mauve
                        strokeWidth: 4
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        PathAngleArc {
                            centerX: 87; centerY: 87
                            radiusX: 85; radiusY: 85
                            startAngle: -90
                            sweepAngle: 360 * root.progress
                            Behavior on sweepAngle {
                                NumberAnimation { duration: 1000; easing.type: Easing.Linear }
                            }
                        }
                    }
                }

                // Album art square
                Rectangle {
                    width: 150; height: 150
                    radius: 10
                    anchors.centerIn: parent
                    color: Colors.surface0
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: root.artUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: root.artUrl === ""
                        text: "󰝚"
                        font.pixelSize: 44
                        font.family: "JetBrainsMono Nerd Font"
                        color: Colors.overlay0
                    }
                }
            }

            Item { width: 1; height: 12 }

            // ── Title ───────────────────────────────────────────────────
            Text {
                width: parent.width
                text: root.player ? (root.player.trackTitle || "Unknown") : ""
                font.pixelSize: 15
                font.weight: Font.Medium
                font.family: "JetBrainsMono Nerd Font"
                color: Colors.text
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
            }

            Item { width: 1; height: 4 }

            // ── Artist ──────────────────────────────────────────────────
            Text {
                width: parent.width
                text: root.player ? (root.player.trackArtist || "") : ""
                font.pixelSize: 12
                font.family: "JetBrainsMono Nerd Font"
                color: Colors.subtext0
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
            }

            Item { width: 1; height: 12 }

            // ── Timestamps + progress bar ───────────────────────────────
            Item {
                width: parent.width
                height: 24
                visible: root.player !== null
                    && root.player.lengthSupported
                    && root.player.length > 0

                Text {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    text: root.formatTime(root.player ? root.player.position : 0)
                    font.pixelSize: 10
                    font.family: "JetBrainsMono Nerd Font"
                    color: Colors.overlay1
                }

                Text {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    text: root.formatTime(root.player ? root.player.length : 0)
                    font.pixelSize: 10
                    font.family: "JetBrainsMono Nerd Font"
                    color: Colors.overlay1
                }

                Rectangle {
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                    anchors.leftMargin: 36; anchors.rightMargin: 36
                    height: 3; radius: 2; color: Colors.surface1

                    Rectangle {
                        width: root.progress > 0 ? parent.width * root.progress : 0
                        height: parent.height; radius: parent.radius
                        color: root.isSpotify ? "#1DB954" : Colors.mauve
                        Behavior on width {
                            NumberAnimation { duration: 1000; easing.type: Easing.Linear }
                        }
                    }
                }
            }

            Item { width: 1; height: 10 }

            // ── Controls ────────────────────────────────────────────────
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6

                PopupBtn {
                    icon: "󰒮"
                    active: root.player && root.player.canGoPrevious
                    onTap: if (root.player) root.player.previous()
                }
                PopupBtn {
                    icon: root.player && root.player.isPlaying ? "󰏤" : "󰐊"
                    active: root.player && root.player.canTogglePlaying
                    large: true
                    accent: root.isSpotify && root.player && root.player.isPlaying
                    onTap: if (root.player) root.player.togglePlaying()
                }
                PopupBtn {
                    icon: "󰒭"
                    active: root.player && root.player.canGoNext
                    onTap: if (root.player) root.player.next()
                }
            }

            Item { width: 1; height: 10 }

            // ── Audio visualizer ────────────────────────────────────────
            CavaWidget {
                anchors.horizontalCenter: parent.horizontalCenter
                bars: 24
                barWidth: 8
                spacing: 2
                implicitHeight: 28
                playing: root.player !== null && root.player.isPlaying
                barColor: root.isSpotify ? "#1DB954" : Colors.mauve
            }

            // ── Player selector — only shown when 2+ players are open ───
            Item {
                width: parent.width
                height: playerSelector.visible ? playerSelector.implicitHeight + 10 : 0
                visible: Mpris.players.values.length > 1

                Rectangle {
                    anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 6 }
                    height: 1; color: Colors.surface1
                }

                Row {
                    id: playerSelector
                    anchors { top: parent.top; topMargin: 14; horizontalCenter: parent.horizontalCenter }
                    spacing: 6

                    Repeater {
                        model: Mpris.players.values

                        Rectangle {
                            property string identity: modelData ? (modelData.identity || "") : ""
                            property bool   active:   root.player === modelData

                            implicitWidth:  pLabel.implicitWidth + 16
                            implicitHeight: 22
                            radius: 11
                            color: active ? Colors.surface2 : Colors.surface0
                            border.width: 1
                            border.color: active ? Colors.mauve : Colors.surface1

                            Text {
                                id: pLabel
                                anchors.centerIn: parent
                                text: parent.identity
                                font.pixelSize: 10
                                font.family: "JetBrainsMono Nerd Font"
                                color: parent.active ? Colors.text : Colors.subtext0
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    // Click active pill → reset to auto; click other → pin it
                                    root.selectedIdentity =
                                        root.selectedIdentity === parent.identity ? "" : parent.identity
                                }
                            }
                        }
                    }
                }
            }

            Item { width: 1; height: 4 }
        }
    }

    component PopupBtn: Item {
        property string icon: ""
        property bool   active: true
        property bool   large:  false
        property bool   accent: false
        signal tap

        width: large ? 46 : 38; height: width

        Rectangle {
            anchors.fill: parent; radius: width / 2
            color: accent
                   ? Qt.rgba(0x1D/255, 0xB9/255, 0x54/255, 0.18)
                   : (ma.containsMouse ? Colors.surface1 : "transparent")
            Behavior on color { ColorAnimation { duration: 100 } }
        }

        Text {
            anchors.centerIn: parent
            text: parent.icon
            font.pixelSize: parent.large ? 24 : 18
            font.family: "JetBrainsMono Nerd Font"
            color: !parent.active  ? Colors.overlay0
                 : parent.accent   ? "#1DB954"
                 : Colors.text
        }

        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: parent.tap() }
    }
}

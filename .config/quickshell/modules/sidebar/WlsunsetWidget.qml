import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import Qs

Item {
    id: root
    implicitHeight: col.implicitHeight

    required property bool active

    property bool running:       false
    property real dayTemp:       5700
    property real nightTemp:     3000
    property real latitude:      51.2
    property real longitude:     5.7
    property bool draggingDay:   false
    property bool draggingNight: false
    property bool _restarting:   false

    onActiveChanged: if (active) pgrepProc.running = true

    // ── Managed wlsunset process ──────────────────────────────────────────────
    // Running wlsunset directly so Process tracks its lifetime — no pgrep race.

    Process {
        id: wlsunsetProc
        command: [
            "wlsunset",
            "-l", root.latitude.toString(),
            "-L", root.longitude.toString(),
            "-T", Math.round(root.dayTemp).toString(),
            "-t", Math.round(root.nightTemp).toString()
        ]
        // Suppress flicker during restart; let onExited restore running=true
        onRunningChanged: if (!root._restarting) root.running = running
        onExited: {
            if (root._restarting) {
                root._restarting = false
                wlsunsetProc.running = true
            }
        }
    }

    // Kill any external wlsunset (e.g. Hyprland autostart)
    Process {
        id: killProc
        property bool andStart: false
        command: ["pkill", "wlsunset"]
        onExited: {
            if (andStart) {
                andStart = false
                wlsunsetProc.running = true
            } else {
                root.running = false
            }
        }
    }

    // ── Polling — detects externally started instances ────────────────────────

    Timer {
        interval: 5000
        running: root.active
        repeat: true
        onTriggered: pgrepProc.running = true
    }

    Process {
        id: pgrepProc
        command: ["bash", "-c", "pgrep wlsunset >/dev/null && echo 1 || echo 0"]
        stdout: SplitParser {
            // Don't override state while we're managing the process directly
            onRead: line => { if (!wlsunsetProc.running) root.running = line.trim() === "1" }
        }
    }

    // ── Config persistence ────────────────────────────────────────────────────

    Process {
        id: loadProc
        command: ["bash", "-c",
            "cat ~/.config/quickshell/data/wlsunset.json 2>/dev/null || echo '{}'"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    const cfg = JSON.parse(line)
                    if (cfg.dayTemp)   root.dayTemp   = cfg.dayTemp
                    if (cfg.nightTemp) root.nightTemp = cfg.nightTemp
                    if (cfg.latitude)  root.latitude  = cfg.latitude
                    if (cfg.longitude) root.longitude = cfg.longitude
                } catch (e) {}
            }
        }
        onExited: pgrepProc.running = true
    }

    Process {
        id: saveProc
        property string payload: "{}"
        command: [
            "python3", "-c",
            "import sys,pathlib; p=pathlib.Path.home()/'.config/quickshell/data/wlsunset.json'; p.parent.mkdir(parents=True,exist_ok=True); p.write_text(sys.argv[1])",
            payload
        ]
    }

    function saveConfig() {
        saveProc.payload = JSON.stringify({
            dayTemp:   Math.round(root.dayTemp),
            nightTemp: Math.round(root.nightTemp),
            latitude:  root.latitude,
            longitude: root.longitude
        })
        saveProc.running = true
    }

    function toggle() {
        saveConfig()
        if (root.running) {
            if (wlsunsetProc.running) {
                wlsunsetProc.running = false
            } else {
                // External instance (e.g. from Hyprland autostart) — kill it
                root.running = false
                killProc.andStart = false
                killProc.running = true
            }
        } else {
            wlsunsetProc.running = true
        }
    }

    function saveAndRestart() {
        saveConfig()
        if (root._restarting) return
        if (wlsunsetProc.running) {
            root._restarting = true
            wlsunsetProc.running = false
        } else if (root.running) {
            // External instance — kill and restart as managed
            killProc.andStart = true
            killProc.running = true
        }
    }

    Component.onCompleted: loadProc.running = true

    // ── UI ───────────────────────────────────────────────────────────────────

    Column {
        id: col
        width: parent.width
        spacing: 8

        SectionHeader {
            width: parent.width
            label: "NIGHT LIGHT"
            accent: Colors.peach
        }

        Rectangle {
            width: parent.width
            height: cardCol.implicitHeight + 20
            color: Colors.surface0
            radius: 8

            Column {
                id: cardCol
                anchors {
                    left: parent.left; right: parent.right
                    leftMargin: 12; rightMargin: 12
                    top: parent.top; topMargin: 10
                }
                spacing: 10

                // Status row + toggle
                Item {
                    width: parent.width
                    height: 28

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Text {
                            text: root.running ? "󰖙" : "󰖔"
                            font.pixelSize: 16
                            font.family: "JetBrainsMono Nerd Font"
                            color: root.running ? Colors.peach : Colors.overlay0
                        }

                        Text {
                            text: root.running ? "Active" : "Inactive"
                            font.pixelSize: 12
                            color: root.running ? Colors.text : Colors.overlay0
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 44; height: 24; radius: 12
                        color: root.running ? Colors.peach : Colors.surface2

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Rectangle {
                            width: 18; height: 18; radius: 9
                            anchors.verticalCenter: parent.verticalCenter
                            x: root.running ? parent.width - width - 3 : 3
                            color: Colors.base

                            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggle()
                        }
                    }
                }

                Rectangle {
                    width: parent.width; height: 1
                    color: Colors.surface1
                }

                // Day temperature
                Item {
                    width: parent.width; height: 16

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰖨  Day"
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"
                        color: Colors.text
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: Math.round(root.dayTemp) + "K"
                        font.pixelSize: 12
                        color: Colors.subtext0
                    }
                }

                Slider {
                    id: daySlider
                    width: parent.width
                    from: 4000; to: 6500
                    value: root.dayTemp
                    onPressedChanged: {
                        root.draggingDay = pressed
                        if (!pressed) root.saveAndRestart()
                    }
                    onMoved: root.dayTemp = value

                    background: Rectangle {
                        x: daySlider.leftPadding
                        y: daySlider.topPadding + daySlider.availableHeight / 2 - height / 2
                        width: daySlider.availableWidth; height: 5; radius: 3
                        color: Colors.surface1
                        Rectangle {
                            width: daySlider.visualPosition * parent.width
                            height: parent.height; radius: parent.radius
                            color: Colors.peach
                        }
                    }

                    handle: Rectangle {
                        x: daySlider.leftPadding + daySlider.visualPosition * (daySlider.availableWidth - width)
                        y: daySlider.topPadding + daySlider.availableHeight / 2 - height / 2
                        width: 14; height: 14; radius: 7
                        color: Colors.peach
                    }
                }

                // Night temperature
                Item {
                    width: parent.width; height: 16

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰖔  Night"
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"
                        color: Colors.text
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: Math.round(root.nightTemp) + "K"
                        font.pixelSize: 12
                        color: Colors.subtext0
                    }
                }

                Slider {
                    id: nightSlider
                    width: parent.width
                    from: 2000; to: 5000
                    value: root.nightTemp
                    onPressedChanged: {
                        root.draggingNight = pressed
                        if (!pressed) root.saveAndRestart()
                    }
                    onMoved: root.nightTemp = value

                    background: Rectangle {
                        x: nightSlider.leftPadding
                        y: nightSlider.topPadding + nightSlider.availableHeight / 2 - height / 2
                        width: nightSlider.availableWidth; height: 5; radius: 3
                        color: Colors.surface1
                        Rectangle {
                            width: nightSlider.visualPosition * parent.width
                            height: parent.height; radius: parent.radius
                            color: Colors.peach
                        }
                    }

                    handle: Rectangle {
                        x: nightSlider.leftPadding + nightSlider.visualPosition * (nightSlider.availableWidth - width)
                        y: nightSlider.topPadding + nightSlider.availableHeight / 2 - height / 2
                        width: 14; height: 14; radius: 7
                        color: Colors.peach
                    }
                }
            }
        }
    }
}

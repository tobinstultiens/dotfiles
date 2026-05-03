import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts
import Qs
import "../.." 1.0

PanelWindow {
    id: root

    required screen

    // Shared state objects passed in from shell.qml
    property QtObject powerMenuState:   null
    property QtObject mediaPopupState:  null
    property QtObject vpnPopupState:    null
    property QtObject audioPopupState:  null
    property QtObject btPopupState:     null
    property QtObject networkPopupState: null

    implicitHeight: 44

    anchors {
        top: true
        left: true
        right: true
    }

    // Reserve space — windows won't overlap the bar
    exclusionMode: ExclusionMode.Auto

    color: "transparent"

    // WindowTitle anchored to the fixed bar height
    WindowTitle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
    }

    // Background
    Rectangle {
        anchors.fill: parent
        color: "transparent"

        RowLayout {
            anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
            spacing: 0

            // ── Left ─────────────────────────────────────────────────
            Row {
                spacing: 8
                Layout.alignment: Qt.AlignVCenter

                WorkspacesWidget {
                    barScreen: root.screen
                    height: root.height
                }

                BarMediaWidget {
                    id: mediaWidget
                    height: root.height
                    onPopupToggled: {
                        if (root.mediaPopupState) {
                            root.mediaPopupState.popupX = mediaWidget.mapToItem(null, 0, 0).x
                            root.mediaPopupState.open = !root.mediaPopupState.open
                        }
                    }
                }
            }

            // ── Spacer ────────────────────────────────────────────────
            Item { Layout.fillWidth: true }

            // ── Right ─────────────────────────────────────────────────
            Row {
                spacing: 6
                Layout.alignment: Qt.AlignVCenter

                // Recording indicator — only visible while recording
                RecordingPill {
                    height: root.height
                    visible: RecorderService.running
                }

                // VPN indicator
                VPNPill {
                    id: vpnPillInst
                    height: root.height
                    onPillClicked: (x) => {
                        if (root.vpnPopupState) {
                            root.vpnPopupState.popupX = x
                            root.vpnPopupState.open = !root.vpnPopupState.open
                        }
                    }
                }

                // Network indicator
                NetworkPill {
                    height: root.height
                    onPillClicked: (x) => {
                        if (root.networkPopupState) {
                            root.networkPopupState.popupX = x
                            root.networkPopupState.open = !root.networkPopupState.open
                        }
                    }
                }

                // Bluetooth indicator
                BluetoothPill {
                    height: root.height
                    onPillClicked: (x) => {
                        if (root.btPopupState) {
                            root.btPopupState.popupX = x
                            root.btPopupState.open = !root.btPopupState.open
                        }
                    }
                }

                UPowerDevice {
                    height: root.height
                    nativePath: "/org/bluez/hci0/dev_68_6C_E6_73_39_C9"
                    icon: "󰊴"
                }

                UPowerDevice {
                    height: root.height
                    nativePath: "/org/bluez/hci0/dev_AC_80_0A_22_A8_F9"
                    icon: "󱡏"
                }

                UPowerDevice {
                    height: root.height
                    nativePath: "hidpp_battery_9"
                    icon: "󰍽"
                }

                VolumeWidget {
                    height: root.height
                    onPopupRequested: (x) => {
                        if (root.audioPopupState) {
                            root.audioPopupState.popupX = x
                            root.audioPopupState.open = !root.audioPopupState.open
                        }
                    }
                }

                MicWidget {
                    height: root.height
                }

                // CPU pill
                Pill {
                    height: root.height
                    icon: {
                        const p = SystemInfo ? SystemInfo.cpuPercent : 0
                        if (p >= 80) return "󰻘"
                        return "󰘚"
                    }
                    iconColor: {
                        const p = SystemInfo ? SystemInfo.cpuPercent : 0
                        if (p >= 80) return Colors.red
                        if (p >= 40) return Colors.yellow
                        return Colors.blue
                    }
                    value: SystemInfo ? Math.round(SystemInfo.cpuPercent) + "%" : "—%"
                }

                // RAM pill
                Pill {
                    height: root.height
                    icon: "󰍛"
                    iconColor: Colors.mauve
                    value: SystemInfo ? Math.round(SystemInfo.ramPercent) + "%" : "—%"
                }

                // Temperature pill
                Pill {
                    height: root.height
                    icon: SystemInfo && SystemInfo.tempCelsius >= 80 ? "󰈸" : "󰔏"
                    iconColor: SystemInfo && SystemInfo.tempCelsius >= 80 ? Colors.red : Colors.peach
                    value: SystemInfo ? SystemInfo.tempCelsius + "°" : "—°"
                }

                // Clock pill
                ClockPill {
                    height: root.height
                }

                // Tray pill
                Item {
                    height: root.height
                    implicitWidth: trayPillRect.implicitWidth

                    Rectangle {
                        id: trayPillRect
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: trayWidgetInner.implicitWidth + 16
                        height: Colors.pillHeight
                        radius: 8
                        color: Colors.surface0

                        TrayWidget {
                            id: trayWidgetInner
                            anchors.centerIn: parent
                            height: parent.height
                            barWindow: root
                        }
                    }
                }

                // Power menu toggle pill
                Item {
                    height: root.height
                    implicitWidth: powerPillRect.implicitWidth

                    readonly property bool menuOpen: root.powerMenuState ? root.powerMenuState.open : false

                    Rectangle {
                        id: powerPillRect
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: powerPillIcon.implicitWidth + 24
                        height: Colors.pillHeight
                        radius: 8
                        color: parent.menuOpen
                               ? Qt.rgba(Colors.red.r, Colors.red.g, Colors.red.b, 0.2)
                               : Colors.surface0
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            id: powerPillIcon
                            anchors.centerIn: parent
                            text: "󰐥"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 16
                            color: parent.parent.menuOpen ? Colors.red : Colors.subtext0
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (root.powerMenuState)
                                    root.powerMenuState.open = !root.powerMenuState.open
                            }
                        }
                    }
                }
            }
        }
    }

    // Reusable inline pill component
    component Pill: Item {
        property string icon:      ""
        property string value:     ""
        property color  iconColor: Colors.blue
        property color  textColor: Colors.text
        property int    iconSize:  16
        implicitWidth: pillRect.implicitWidth
        implicitHeight: parent.height

        Rectangle {
            id: pillRect
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: pillIcon.implicitWidth + pillValue.implicitWidth + 24
            height: Colors.pillHeight
            radius: 8
            color: Colors.surface0

            Row {
                anchors.centerIn: parent
                spacing: 5

                Text {
                    id: pillIcon
                    text: pillRect.parent.icon
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: pillRect.parent.iconSize
                    color: pillRect.parent.iconColor
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    id: pillValue
                    text: pillRect.parent.value
                    font.pixelSize: 12
                    font.family: "JetBrainsMono Nerd Font"
                    color: pillRect.parent.textColor
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    // Clock with SystemClock binding
    component ClockPill: Item {
        id: clockPill
        implicitWidth: clockRect.implicitWidth
        implicitHeight: parent.height

        property var now: new Date()
        SystemClock {
            precision: SystemClock.Minutes
            onDateChanged: clockPill.now = new Date()
        }

        Rectangle {
            id: clockRect
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: clockText.implicitWidth + 20
            height: Colors.pillHeight
            radius: 8
            color: Colors.surface0

            Text {
                id: clockText
                anchors.centerIn: parent
                text: Qt.formatDateTime(clockPill.now, "HH:mm")
                font.pixelSize: 13
                font.family: "JetBrainsMono Nerd Font"
                color: Colors.text
            }
        }
    }

    // ── Recording indicator pill ─────────────────────────────────────────
    component RecordingPill: Item {
        implicitWidth: recRect.implicitWidth
        implicitHeight: parent.height

        Rectangle {
            id: recRect
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: recRow.implicitWidth + 18
            height: Colors.pillHeight
            radius: 8
            color: Colors.surface0
            border.width: 1
            border.color: Qt.rgba(Colors.red.r, Colors.red.g, Colors.red.b, 0.5)

            Row {
                id: recRow
                anchors.centerIn: parent
                spacing: 6

                // Pulsing red dot
                Rectangle {
                    id: recDot
                    width: 8; height: 8; radius: 4
                    anchors.verticalCenter: parent.verticalCenter
                    color: Colors.red
                    // Paused: dim; not recording: full; recording: animation overrides
                    opacity: RecorderService ? (RecorderService.paused ? 0.4 : 1.0) : 1.0

                    SequentialAnimation {
                        id: dotPulse
                        running: RecorderService ? (RecorderService.running && !RecorderService.paused) : false
                        loops: Animation.Infinite
                        NumberAnimation { target: recDot; property: "opacity"; from: 1; to: 0.3; duration: 600 }
                        NumberAnimation { target: recDot; property: "opacity"; from: 0.3; to: 1; duration: 600 }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: RecorderService.formatElapsed()
                    font.pixelSize: 12
                    font.family: "JetBrainsMono Nerd Font"
                    color: Colors.text
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: RecorderService.stop()
                onPressAndHold: RecorderService.togglePause()
            }
        }
    }

    // ── VPN status pill ─────────────────────────────────────────────────
    component VPNPill: Item {
        id: vpnPillComp
        implicitWidth: vpnRect.implicitWidth
        implicitHeight: parent.height
        signal pillClicked(real screenX)

        readonly property color _activeColor: {
            if (VPNService.piaConnected && VPNService.tsConnected) return Colors.teal
            if (VPNService.piaConnected) return Colors.green
            if (VPNService.tsConnected)  return Colors.mauve
            return Colors.overlay1
        }

        Rectangle {
            id: vpnRect
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: vpnRow.implicitWidth + 18
            height: Colors.pillHeight
            radius: 8
            color: Colors.surface0
            border.width: 1
            border.color: (VPNService.anyConnected || VPNService.piaState === "Connecting")
                          ? Qt.rgba(vpnPillComp._activeColor.r, vpnPillComp._activeColor.g,
                                    vpnPillComp._activeColor.b, 0.5)
                          : "transparent"
            Behavior on border.color { ColorAnimation { duration: 300 } }

            Row {
                id: vpnRow
                anchors.centerIn: parent
                spacing: 5

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰒄"
                    font.pixelSize: 14
                    font.family: "JetBrainsMono Nerd Font"
                    color: vpnPillComp._activeColor
                    Behavior on color { ColorAnimation { duration: 300 } }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: {
                        if (VPNService.piaConnected && VPNService.tsConnected) return "PIA+TS"
                        if (VPNService.piaState === "Connecting")               return "PIA…"
                        if (VPNService.piaConnected)                            return "PIA"
                        if (VPNService.tsConnected)                             return "TS"
                        return "VPN"
                    }
                    font.pixelSize: 11
                    font.family: "JetBrainsMono Nerd Font"
                    color: vpnPillComp._activeColor
                    Behavior on color { ColorAnimation { duration: 300 } }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: vpnPillComp.pillClicked(vpnPillComp.mapToItem(null, 0, 0).x)
            }
        }
    }

    // ── Network pill ─────────────────────────────────────────────────────
    component NetworkPill: Item {
        id: netPillComp
        implicitWidth: netRect.implicitWidth
        implicitHeight: parent.height
        signal pillClicked(real screenX)

        property string _ssid: ""
        property string _type: "wifi"   // "wifi", "ethernet", "none"
        property string _buf:  ""

        // Poll current connection every 15s.
        // Uses 'nmcli d' (device state) which is reliable for both ethernet and wifi.
        Process {
            id: netCheckProc
            command: ["bash", "-c",
                "eth=$(nmcli -t -f DEVICE,TYPE,STATE d 2>/dev/null | awk -F: '$2==\"ethernet\"&&$3==\"connected\"{print $1;exit}');" +
                "if [ -n \"$eth\" ]; then echo \"ethernet:LAN\"; exit; fi;" +
                "wdev=$(nmcli -t -f DEVICE,TYPE,STATE d 2>/dev/null | awk -F: '$2==\"wifi\"&&$3==\"connected\"{print $1;exit}');" +
                "if [ -n \"$wdev\" ]; then" +
                "  ssid=$(nmcli -t -f GENERAL.CONNECTION d show \"$wdev\" 2>/dev/null | awk -F: 'NR==1{print $2}');" +
                "  echo \"wifi:$ssid\"; exit; fi;" +
                "echo 'none:'"]
            stdout: SplitParser { onRead: line => netPillComp._buf += line.trim() }
            onExited: {
                var raw   = netPillComp._buf.trim()
                var colon = raw.indexOf(":")
                var type  = colon >= 0 ? raw.slice(0, colon) : "none"
                var label = colon >= 0 ? raw.slice(colon + 1) : ""
                netPillComp._type = type
                netPillComp._ssid = label
                netPillComp._buf  = ""
            }
        }

        Timer {
            interval: 15000; running: true; repeat: true; triggeredOnStart: true
            onTriggered: netCheckProc.running = true
        }

        Rectangle {
            id: netRect
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: netRow.implicitWidth + 18
            height: Colors.pillHeight; radius: 8
            color: Colors.surface0

            Row {
                id: netRow
                anchors.centerIn: parent
                spacing: 5

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: netPillComp._type === "wifi"     ? "󰤨"
                        : netPillComp._type === "ethernet" ? "󰈁"
                        : "󰤭"
                    font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font"
                    color: netPillComp._type !== "none" ? Colors.green : Colors.overlay1
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: netPillComp._ssid !== ""
                    text: netPillComp._ssid.length > 12
                          ? netPillComp._ssid.slice(0, 11) + "…" : netPillComp._ssid
                    font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"
                    color: Colors.text
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: netPillComp.pillClicked(netPillComp.mapToItem(null, 0, 0).x)
            }
        }
    }

    // ── Bluetooth pill ───────────────────────────────────────────────────
    component BluetoothPill: Item {
        id: btPillComp
        implicitWidth: btRect.implicitWidth
        implicitHeight: parent.height
        signal pillClicked(real screenX)

        // Derived state — computed once, reused in multiple bindings
        readonly property bool _btEnabled:   Bluetooth.defaultAdapter !== null && Bluetooth.defaultAdapter.enabled
        readonly property int  _btConnected: Bluetooth.devices.values.filter(d => d.connected).length

        Rectangle {
            id: btRect
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: btRow.implicitWidth + 18
            height: Colors.pillHeight; radius: 8
            color: Colors.surface0
            border.width: 1
            // Dim border when on but nothing connected; full border when a device is connected
            border.color: btPillComp._btConnected > 0
                          ? Qt.rgba(Colors.blue.r, Colors.blue.g, Colors.blue.b, 0.6)
                          : btPillComp._btEnabled
                            ? Qt.rgba(Colors.blue.r, Colors.blue.g, Colors.blue.b, 0.25)
                            : "transparent"
            Behavior on border.color { ColorAnimation { duration: 300 } }

            Row {
                id: btRow
                anchors.centerIn: parent
                spacing: 5

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰂯"
                    font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font"
                    // overlay1 when off, subtext0 when on, blue when device connected
                    color: btPillComp._btConnected > 0 ? Colors.blue
                         : btPillComp._btEnabled       ? Colors.subtext0
                         : Colors.overlay1
                    Behavior on color { ColorAnimation { duration: 300 } }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: btPillComp._btConnected > 0
                    text: btPillComp._btConnected.toString()
                    font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"
                    color: Colors.blue
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: btPillComp.pillClicked(btPillComp.mapToItem(null, 0, 0).x)
            }
        }
    }
}

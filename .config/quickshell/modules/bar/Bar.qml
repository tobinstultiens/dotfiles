import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import Qs
import "../.." 1.0

PanelWindow {
    id: root

    required screen

    // Shared state objects passed in from shell.qml
    property QtObject powerMenuState:  null
    property QtObject mediaPopupState: null

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
                    height: root.height
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
        implicitWidth: vpnRect.implicitWidth
        implicitHeight: parent.height

        Rectangle {
            id: vpnRect
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: vpnRow.implicitWidth + 18
            height: Colors.pillHeight
            radius: 8
            color: Colors.surface0
            border.width: 1
            border.color: Qt.rgba(Colors.green.r, Colors.green.g, Colors.green.b,
                                  VPNService.connected ? 0.5 : 0)
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
                    color: VPNService.connected ? Colors.green : Colors.overlay1
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: VPNService.type === "wireguard" ? "WG" : "VPN"
                    font.pixelSize: 11
                    font.family: "JetBrainsMono Nerd Font"
                    color: VPNService.connected ? Colors.green : Colors.subtext1
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: VPNService.toggle()
            }
        }
    }
}

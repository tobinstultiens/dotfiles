import QtQuick
import Qs
import "../.." 1.0

Item {
    id: root
    implicitHeight: col.implicitHeight

    Column {
        id: col
        width: parent.width
        spacing: 0

        SectionHeader { width: parent.width; label: "RAIN · 2H"; accent: Colors.blue }

        Rectangle {
            width: parent.width
            implicitHeight: inner.implicitHeight + 24
            color: Colors.surface0
            radius: 8

            Column {
                id: inner
                anchors {
                    top: parent.top; topMargin: 14
                    left: parent.left; leftMargin: 14
                    right: parent.right; rightMargin: 14
                }
                spacing: 6

                // ── Status line ───────────────────────────────────────────
                Row {
                    spacing: 6

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰖗"
                        font.pixelSize: 13; font.family: "JetBrainsMono Nerd Font"
                        color: RainService.hasRain ? Colors.blue : Colors.overlay0
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: RainService.hasData
                              ? (RainService.hasRain
                                 ? "Rain forecast — max " + RainService.maxMmh.toFixed(1) + " mm/h"
                                 : "No rain expected")
                              : "Loading…"
                        font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"
                        color: RainService.hasRain ? Colors.subtext0 : Colors.overlay0
                    }
                }

                // ── Bar chart ─────────────────────────────────────────────
                Item {
                    width: parent.width
                    height: 56

                    // Subtle horizontal grid lines at 25%, 50%, 75%
                    Repeater {
                        model: [0.25, 0.5, 0.75]
                        Rectangle {
                            width: parent.width
                            height: 1
                            y: parent.height * (1 - modelData) - 1
                            color: Colors.surface1
                        }
                    }

                    // Baseline
                    Rectangle {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: 1; color: Colors.surface2
                    }

                    // Bars — one per 5-minute interval
                    Row {
                        anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom }
                        spacing: 1

                        Repeater {
                            model: RainService.readings

                            Rectangle {
                                id: bar
                                readonly property real ratio: modelData.mmh / RainService.maxMmh
                                width:  (parent.width - (RainService.readings.length - 1))
                                        / Math.max(1, RainService.readings.length)
                                height: modelData.mmh > 0
                                        ? Math.max(3, ratio * parent.height)
                                        : 0
                                anchors.bottom: parent.bottom
                                radius: 1

                                // Colour: sky → blue → sapphire as intensity increases
                                color: {
                                    var mmh = modelData.mmh
                                    if (mmh <= 0)   return "transparent"
                                    if (mmh < 0.5)  return Qt.rgba(Colors.sky.r, Colors.sky.g, Colors.sky.b, 0.5)
                                    if (mmh < 2)    return Colors.blue
                                    if (mmh < 7)    return Colors.sapphire
                                    return Colors.lavender
                                }

                                Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                            }
                        }
                    }
                }

                // ── Time axis labels ──────────────────────────────────────
                Item {
                    width: parent.width
                    height: 14

                    // "Now" at left, "+30m" at 25%, "+1h" at centre,
                    // "+1h30" at 75%, "+2h" at right
                    Repeater {
                        model: [
                            { label: "Now",   frac: 0.0  },
                            { label: "+30m",  frac: 0.25 },
                            { label: "+1h",   frac: 0.5  },
                            { label: "+1h30", frac: 0.75 },
                            { label: "+2h",   frac: 1.0  }
                        ]

                        Text {
                            text: modelData.label
                            font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font"
                            color: Colors.overlay0
                            x: Math.max(0, Math.min(
                                parent.width - implicitWidth,
                                modelData.frac * parent.width - implicitWidth / 2))
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }
}

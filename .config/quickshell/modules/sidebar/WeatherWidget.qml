import QtQuick
import Qs
import "../.." 1.0

Item {
    id: root
    implicitHeight: col.implicitHeight
    visible: WeatherService.hasData

    // "2026-05-03" → "Today" / "Tmrw" / "Mon" etc.
    function dayLabel(dateStr) {
        if (!dateStr) return ""
        var today = Qt.formatDate(new Date(), "yyyy-MM-dd")
        if (dateStr === today) return "Today"
        var names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return names[new Date(dateStr + "T12:00:00").getDay()]
    }

    Column {
        id: col
        width: parent.width
        spacing: 0

        SectionHeader { width: parent.width; label: "WEATHER"; accent: Colors.sapphire }

        Rectangle {
            width: parent.width
            implicitHeight: content.implicitHeight + 20
            color: Colors.surface0
            radius: 8

            Column {
                id: content
                anchors {
                    left: parent.left; right: parent.right
                    top: parent.top
                    margins: 14
                }
                spacing: 12

                // ── Current conditions ────────────────────────────────────
                Row {
                    width: parent.width
                    spacing: 10

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: WeatherService.currentIcon
                            font.pixelSize: 32; font.family: "JetBrainsMono Nerd Font"
                            color: Colors.text
                        }
                        Text {
                            text: WeatherService.currentTemp + "°C"
                            font.pixelSize: 22; font.weight: Font.Medium
                            font.family: "JetBrainsMono Nerd Font"
                            color: Colors.text
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Text {
                            text: WeatherService.currentDesc
                            font.pixelSize: 13; font.family: "JetBrainsMono Nerd Font"
                            color: Colors.subtext1
                        }
                        Row {
                            spacing: 12
                            Row {
                                spacing: 4
                                Text { text: "󰜗"; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"; color: Colors.overlay1; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: WeatherService.currentWind + " km/h"; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"; color: Colors.overlay1; anchors.verticalCenter: parent.verticalCenter }
                            }
                            Row {
                                spacing: 4
                                Text { text: "󰖎"; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"; color: Colors.overlay1; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: WeatherService.currentHumidity + "%"; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"; color: Colors.overlay1; anchors.verticalCenter: parent.verticalCenter }
                            }
                        }
                    }
                }

                // Hairline divider
                Rectangle { width: parent.width; height: 1; color: Colors.surface1 }

                // ── 5-day forecast ────────────────────────────────────────
                Row {
                    width: parent.width
                    spacing: 0

                    Repeater {
                        model: WeatherService.forecast

                        Item {
                            width: parent.width / WeatherService.forecast.length
                            implicitHeight: dayCol.implicitHeight

                            Column {
                                id: dayCol
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 3

                                // Day label — "Today", "Tmrw", "Mon" …
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.dayLabel(modelData.date)
                                    font.pixelSize: 10
                                    font.family: "JetBrainsMono Nerd Font"
                                    color: modelData.date === Qt.formatDate(new Date(), "yyyy-MM-dd")
                                           ? Colors.sapphire : Colors.overlay1
                                }

                                // Weather icon
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.icon
                                    font.pixelSize: 16; font.family: "JetBrainsMono Nerd Font"
                                    color: Colors.subtext1
                                }

                                // High temperature with up arrow
                                Row {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: 1
                                    Text {
                                        text: "↑"
                                        font.pixelSize: 8; font.family: "JetBrainsMono Nerd Font"
                                        color: Colors.peach
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: modelData.high + "°"
                                        font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"
                                        color: Colors.text
                                    }
                                }

                                // Low temperature with down arrow
                                Row {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: 1
                                    Text {
                                        text: "↓"
                                        font.pixelSize: 8; font.family: "JetBrainsMono Nerd Font"
                                        color: Colors.blue
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: modelData.low + "°"
                                        font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"
                                        color: Colors.overlay1
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

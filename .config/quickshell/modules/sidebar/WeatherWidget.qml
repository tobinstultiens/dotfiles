import QtQuick
import Qs
import "../.." 1.0

Item {
    id: root
    implicitHeight: col.implicitHeight
    visible: WeatherService.hasData

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
                spacing: 10

                // ── Current conditions ────────────────────────────────────
                Row {
                    width: parent.width
                    spacing: 10

                    // Big icon + temp
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: WeatherService.currentIcon
                            font.pixelSize: 32
                            font.family: "JetBrainsMono Nerd Font"
                            color: Colors.text
                        }

                        Text {
                            text: WeatherService.currentTemp + "°C"
                            font.pixelSize: 22
                            font.weight: Font.Medium
                            font.family: "JetBrainsMono Nerd Font"
                            color: Colors.text
                        }
                    }

                    // Description + wind + humidity
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Text {
                            text: WeatherService.currentDesc
                            font.pixelSize: 13
                            font.family: "JetBrainsMono Nerd Font"
                            color: Colors.subtext1
                        }

                        Row {
                            spacing: 12

                            Row {
                                spacing: 4
                                Text {
                                    text: "󰜗"
                                    font.pixelSize: 11
                                    font.family: "JetBrainsMono Nerd Font"
                                    color: Colors.overlay1
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: WeatherService.currentWind + " km/h"
                                    font.pixelSize: 11
                                    font.family: "JetBrainsMono Nerd Font"
                                    color: Colors.overlay1
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Row {
                                spacing: 4
                                Text {
                                    text: "󰖎"
                                    font.pixelSize: 11
                                    font.family: "JetBrainsMono Nerd Font"
                                    color: Colors.overlay1
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: WeatherService.currentHumidity + "%"
                                    font.pixelSize: 11
                                    font.family: "JetBrainsMono Nerd Font"
                                    color: Colors.overlay1
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }
                }

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
                                spacing: 2

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.icon
                                    font.pixelSize: 16
                                    font.family: "JetBrainsMono Nerd Font"
                                    color: Colors.subtext1
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.high + "°"
                                    font.pixelSize: 11
                                    font.family: "JetBrainsMono Nerd Font"
                                    color: Colors.text
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.low + "°"
                                    font.pixelSize: 10
                                    font.family: "JetBrainsMono Nerd Font"
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

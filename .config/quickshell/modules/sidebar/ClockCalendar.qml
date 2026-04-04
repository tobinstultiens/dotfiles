import Quickshell
import QtQuick
import QtQuick.Layouts
import Qs

Item {
    id: root
    implicitHeight: col.implicitHeight

    property var now: new Date()

    SystemClock {
        precision: SystemClock.Seconds
        onDateChanged: root.now = new Date()
    }

    readonly property var monthNames: [
        "January","February","March","April","May","June",
        "July","August","September","October","November","December"
    ]

    readonly property int calYear:     now.getFullYear()
    readonly property int calMonth:    now.getMonth()
    readonly property int today:       now.getDate()
    readonly property int firstDow:    new Date(calYear, calMonth, 1).getDay()
    readonly property int daysInMonth: new Date(calYear, calMonth + 1, 0).getDate()

    Column {
        id: col
        width: parent.width
        spacing: 4

        // Large clock
        Row {
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
                text: Qt.formatDateTime(root.now, "HH:mm")
                font.pixelSize: 64
                font.weight: Font.Light
                color: Colors.text
                anchors.bottom: parent.bottom
            }

            Text {
                text: Qt.formatDateTime(root.now, ":ss")
                font.pixelSize: 36
                font.weight: Font.Light
                color: Colors.subtext0
                anchors.bottom: parent.bottom
                bottomPadding: 6
            }
        }

        // Date line
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: Qt.formatDateTime(root.now, "dddd, MMMM d")
            font.pixelSize: 13
            color: Colors.subtext0
            bottomPadding: 8
        }

        // Divider
        Rectangle {
            width: parent.width
            height: 1
            color: Colors.surface1
        }

        // Month/year header
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.monthNames[root.calMonth] + " " + root.calYear
            font.pixelSize: 13
            font.weight: Font.Medium
            color: Colors.blue
            topPadding: 6
            bottomPadding: 4
        }

        // Day-of-week headers
        Row {
            width: parent.width
            Repeater {
                model: ["Su","Mo","Tu","We","Th","Fr","Sa"]
                delegate: Text {
                    width: parent.width / 7
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    font.pixelSize: 10
                    color: Colors.overlay1
                }
            }
        }

        // Calendar grid
        Grid {
            id: calGrid
            width: parent.width
            columns: 7

            // Leading blank cells
            Repeater {
                model: root.firstDow
                delegate: Item { width: calGrid.width / 7; height: 34 }
            }

            // Day cells
            Repeater {
                model: root.daysInMonth
                delegate: Item {
                    id: dayCell
                    width: calGrid.width / 7
                    height: 34

                    readonly property string dateStr:
                        Qt.formatDate(new Date(root.calYear, root.calMonth, index + 1), "yyyy-MM-dd")
                    readonly property bool isToday:    (index + 1 === root.today)
                    readonly property bool isSelected: (dateStr === TodoService.selectedDate)
                    readonly property bool hasTodos: {
                        var _r = TodoService._revision  // reactive dep
                        return TodoService.hasTodosForDate(dateStr)
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: TodoService.selectedDate = dayCell.dateStr
                    }

                    // Selected-date ring (behind the fill circle)
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 1
                        width: 26; height: 26; radius: 13
                        color: "transparent"
                        border.color: dayCell.isSelected ? Colors.peach : "transparent"
                        border.width: 1.5
                        Behavior on border.color { ColorAnimation { duration: 120 } }
                    }

                    // Day fill circle
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 2
                        width: 24; height: 24; radius: 12
                        color: dayCell.isToday ? Colors.blue : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: index + 1
                            font.pixelSize: 11
                            color: dayCell.isToday ? Colors.base : Colors.text
                            font.weight: dayCell.isToday ? Font.Bold : Font.Normal
                        }
                    }

                    // Todo dot
                    Rectangle {
                        visible: dayCell.hasTodos
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 2
                        width: 4; height: 4; radius: 2
                        color: Colors.peach
                    }
                }
            }
        }
    }
}

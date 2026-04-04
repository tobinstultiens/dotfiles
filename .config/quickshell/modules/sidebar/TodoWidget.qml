import QtQuick
import Qs

Item {
    id: root
    implicitHeight: col.implicitHeight

    // Re-evaluate when model mutates or selected date changes
    property var currentTodos: {
        var _r = TodoService._revision  // reactive dependency
        return TodoService.todosForDate(TodoService.selectedDate)
    }

    Column {
        id: col
        width: parent.width
        spacing: 8

        SectionHeader {
            width: parent.width
            label: "TODOS"
            accent: Colors.peach
        }

        // Date label
        Text {
            text: {
                // Parse as local midnight to avoid timezone-offset day shifts
                var parts = TodoService.selectedDate.split("-")
                var d = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]))
                return Qt.formatDate(d, "dddd, MMMM d")
            }
            font.pixelSize: 11
            color: Colors.subtext0
            leftPadding: 2
        }

        // Todo list card
        Rectangle {
            width: parent.width
            implicitHeight: listCol.implicitHeight + 20
            color: Colors.surface0
            radius: 8

            Column {
                id: listCol
                anchors {
                    left: parent.left; right: parent.right
                    leftMargin: 12; rightMargin: 12
                    top: parent.top; topMargin: 10
                }
                spacing: 0

                // Empty state
                Text {
                    width: parent.width
                    visible: root.currentTodos.length === 0
                    text: "Nothing planned"
                    font.pixelSize: 11
                    color: Colors.overlay0
                    horizontalAlignment: Text.AlignHCenter
                    topPadding: 2
                    bottomPadding: 4
                }

                // Todo items
                Repeater {
                    model: root.currentTodos

                    delegate: Item {
                        width: listCol.width
                        height: 30

                        // Checkbox
                        Rectangle {
                            id: chk
                            anchors.verticalCenter: parent.verticalCenter
                            x: 0
                            width: 14; height: 14; radius: 7
                            color: modelData.done ? Colors.peach : "transparent"
                            border.color: modelData.done ? Colors.peach : Colors.overlay1
                            border.width: 1.5

                            Text {
                                anchors.centerIn: parent
                                visible: modelData.done
                                text: "✓"
                                font.pixelSize: 8
                                font.weight: Font.Bold
                                color: Colors.base
                            }

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -3
                                onClicked: TodoService.toggleTodo(modelData.id)
                            }
                        }

                        // Text
                        Text {
                            anchors {
                                left: chk.right; leftMargin: 8
                                right: delBtn.left; rightMargin: 6
                                verticalCenter: parent.verticalCenter
                            }
                            text: modelData.text
                            font.pixelSize: 12
                            color: modelData.done ? Colors.overlay1 : Colors.text
                            font.strikeout: modelData.done
                            elide: Text.ElideRight
                        }

                        // Delete button
                        Text {
                            id: delBtn
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                            text: "✕"
                            font.pixelSize: 10
                            color: Colors.overlay0
                            opacity: delMa.containsMouse ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 100 } }

                            MouseArea {
                                id: delMa
                                anchors.fill: parent
                                anchors.margins: -4
                                hoverEnabled: true
                                onClicked: TodoService.removeTodo(modelData.id)
                            }
                        }
                    }
                }
            }
        }

        // Add-todo input row
        Rectangle {
            width: parent.width
            height: 34
            color: Colors.surface0
            radius: 8

            TextInput {
                id: todoInput
                anchors {
                    left: parent.left; leftMargin: 12
                    right: addBtn.left; rightMargin: 8
                    verticalCenter: parent.verticalCenter
                }
                font.pixelSize: 12
                color: Colors.text
                selectionColor: Colors.peach
                selectedTextColor: Colors.base
                clip: true

                // Placeholder overlay
                Text {
                    anchors.fill: parent
                    visible: !todoInput.text && !todoInput.activeFocus
                    text: "Add a todo…"
                    font.pixelSize: 12
                    color: Colors.overlay0
                }

                Keys.onReturnPressed: {
                    if (text.trim()) {
                        TodoService.addTodo(TodoService.selectedDate, text)
                        text = ""
                    }
                }
            }

            Text {
                id: addBtn
                anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                text: "+"
                font.pixelSize: 22
                color: todoInput.text.trim() ? Colors.peach : Colors.overlay0
                Behavior on color { ColorAnimation { duration: 100 } }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    onClicked: {
                        if (todoInput.text.trim()) {
                            TodoService.addTodo(TodoService.selectedDate, todoInput.text)
                            todoInput.text = ""
                        }
                    }
                }
            }
        }
    }
}

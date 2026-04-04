import Quickshell.Io
import QtQuick
import Qs

Item {
    id: root
    implicitHeight: col.implicitHeight

    property string _buf: ""
    property bool _loading: false

    // ── File I/O ────────────────────────────────────────────────────────────

    Process {
        id: readProc
        command: ["bash", "-c", "cat ~/.config/quickshell/data/notes.txt 2>/dev/null || true"]
        stdout: SplitParser {
            onRead: line => {
                if (root._buf !== "") root._buf += "\n"
                root._buf += line
            }
        }
        onExited: {
            root._loading = true
            noteEdit.text = root._buf
            root._loading = false
            root._buf = ""
        }
    }

    Process {
        id: writeProc
        property string payload: ""
        command: [
            "python3", "-c",
            "import sys,pathlib; p=pathlib.Path.home()/'.config/quickshell/data/notes.txt'; p.parent.mkdir(parents=True,exist_ok=True); p.write_text(sys.argv[1])",
            payload
        ]
    }

    Timer {
        id: saveTimer
        interval: 1500
        repeat: false
        onTriggered: {
            writeProc.payload = noteEdit.text
            writeProc.running = true
        }
    }

    // ── UI ──────────────────────────────────────────────────────────────────

    Column {
        id: col
        width: parent.width
        spacing: 8

        SectionHeader {
            width: parent.width
            label: "NOTES"
            accent: Colors.lavender
        }

        Rectangle {
            width: parent.width
            height: 220
            color: Colors.surface0
            radius: 8
            clip: true

            TextEdit {
                id: noteEdit
                anchors { fill: parent; margins: 10 }
                textFormat: TextEdit.MarkdownText
                wrapMode: TextEdit.WordWrap
                font.pixelSize: 12
                color: Colors.text
                selectedTextColor: Colors.base
                selectionColor: Colors.lavender

                // Placeholder
                Text {
                    anchors.fill: parent
                    visible: !noteEdit.text && !noteEdit.activeFocus
                    text: "Type a note…"
                    font.pixelSize: 12
                    color: Colors.overlay0
                    wrapMode: TextEdit.WordWrap
                }

                onTextChanged: if (!root._loading) saveTimer.restart()
            }
        }
    }

    Component.onCompleted: readProc.running = true
}

pragma Singleton
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    // Currently selected calendar date (drives TodoWidget display)
    property string selectedDate: Qt.formatDate(new Date(), "yyyy-MM-dd")

    property ListModel todoModel: ListModel {}

    // Incremented on every mutation so external bindings can react
    property int _revision: 0

    property string _readBuf: ""

    // Signals used to cross the QtObject→inner-Item boundary
    signal loadNeeded()
    signal saveNeeded(string jsonData)

    // ── Public API ──────────────────────────────────────────────────────────

    function addTodo(dateStr, text) {
        var trimmed = text.trim()
        if (!trimmed) return
        var id = Date.now().toString(36) + Math.random().toString(36).slice(2, 6)
        todoModel.append({ id: id, date: dateStr, text: trimmed, done: false })
        _revision++
        _doSave()
    }

    function toggleTodo(id) {
        for (var i = 0; i < todoModel.count; i++) {
            if (todoModel.get(i).id === id) {
                todoModel.setProperty(i, "done", !todoModel.get(i).done)
                _revision++
                _doSave()
                return
            }
        }
    }

    function removeTodo(id) {
        for (var i = 0; i < todoModel.count; i++) {
            if (todoModel.get(i).id === id) {
                todoModel.remove(i)
                _revision++
                _doSave()
                return
            }
        }
    }

    function hasTodosForDate(dateStr) {
        for (var i = 0; i < todoModel.count; i++) {
            if (todoModel.get(i).date === dateStr) return true
        }
        return false
    }

    function todosForDate(dateStr) {
        var result = []
        for (var i = 0; i < todoModel.count; i++) {
            var t = todoModel.get(i)
            if (t.date === dateStr)
                result.push({ id: t.id, date: t.date, text: t.text, done: t.done })
        }
        return result
    }

    // ── Internal ─────────────────────────────────────────────────────────────

    function _doSave() {
        var arr = []
        for (var i = 0; i < todoModel.count; i++) {
            var t = todoModel.get(i)
            arr.push({ id: t.id, date: t.date, text: t.text, done: t.done })
        }
        saveNeeded(JSON.stringify(arr))
    }

    // Inner Item hosts Timer/Process children (QtObject has no default data property)
    property var _impl: Item {
        Connections {
            target: root
            function onLoadNeeded() { readProc.running = true }
            function onSaveNeeded(jsonData) {
                writeProc.payload = jsonData
                writeProc.running = true
            }
        }

        Process {
            id: readProc
            command: ["bash", "-c", "cat ~/.config/quickshell/data/todos.json 2>/dev/null || echo '[]'"]
            stdout: SplitParser {
                onRead: line => { root._readBuf += line }
            }
            onExited: {
                try {
                    var arr = JSON.parse(root._readBuf.trim() || "[]")
                    root.todoModel.clear()
                    for (var i = 0; i < arr.length; i++) {
                        root.todoModel.append(arr[i])
                    }
                    root._revision++
                } catch(e) {
                    console.warn("TodoService: failed to parse todos.json:", e)
                }
                root._readBuf = ""
            }
        }

        Process {
            id: writeProc
            property string payload: "[]"
            command: [
                "python3", "-c",
                "import sys,pathlib; p=pathlib.Path.home()/'.config/quickshell/data/todos.json'; p.parent.mkdir(parents=True,exist_ok=True); p.write_text(sys.argv[1])",
                payload
            ]
        }
    }

    Component.onCompleted: loadNeeded()
}

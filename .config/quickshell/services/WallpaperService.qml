pragma Singleton
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    property var monitors: []            // ["DP-1", "DP-2", ...] populated from hyprctl
    property var activeWallpapers: ({})  // {monitorName: wallpaperPath}
    property int _wallpapersRev: 0       // bump on mutation so WallpaperBackground re-evaluates
    property var wallpapers: []          // [{path, name}]

    property string _scanBuf:     ""
    property string _stateBuf:    ""
    property string _monitorsBuf: ""

    signal scanNeeded()
    signal loadStateNeeded()
    signal monitorsNeeded()

    // ── Public API ──────────────────────────────────────────────────────────

    function apply(monitor, path) {
        root.activeWallpapers[monitor] = path
        root._wallpapersRev++
        _saveState()
    }

    // Reading _wallpapersRev makes QML bindings re-evaluate when wallpapers change
    function activeFor(monitor) {
        _wallpapersRev
        return activeWallpapers[monitor] || ""
    }

    // ── Internal ─────────────────────────────────────────────────────────────

    function _saveState() {
        var data = {}
        for (var m in root.activeWallpapers) data[m] = root.activeWallpapers[m]
        _impl.stateWriteProc.command = [
            "python3", "-c",
            "import sys, pathlib; p = pathlib.Path.home() / '.cache/wallpaper-switcher/state.json'; " +
            "p.parent.mkdir(parents=True, exist_ok=True); p.write_text(sys.argv[1])",
            JSON.stringify(data)
        ]
        _impl.stateWriteProc.running = true
    }

    property var _impl: Item {

        Connections {
            target: root
            function onScanNeeded()      { scanProc.running = true }
            function onLoadStateNeeded() { stateReadProc.running = true }
            function onMonitorsNeeded()  { monitorsProc.running = true }
        }

        Process {
            id: monitorsProc
            command: ["bash", "-c", "hyprctl monitors -j 2>/dev/null"]
            stdout: SplitParser { onRead: line => { root._monitorsBuf += line } }
            onExited: {
                try {
                    var mons = JSON.parse(root._monitorsBuf)
                    root.monitors = mons.map(m => m.name)
                    console.log("WallpaperService: monitors:", root.monitors.join(", "))
                } catch(e) {
                    console.warn("WallpaperService: failed to parse monitors:", e)
                }
                root._monitorsBuf = ""
            }
        }

        Process {
            id: scanProc
            command: ["bash", "-c",
                      "find \"$HOME/Pictures/Wallpapers\" -maxdepth 1 -type f " +
                      "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \\) | sort"]
            stdout: SplitParser { onRead: line => { root._scanBuf += line + "\n" } }
            onExited: {
                var lines = root._scanBuf.trim().split("\n").filter(l => l.length > 0)
                root.wallpapers = lines.map(p => ({ path: p, name: p.split("/").pop() }))
                console.log("WallpaperService: found", root.wallpapers.length, "wallpapers")
                root._scanBuf = ""
            }
        }

        Process {
            id: stateReadProc
            command: ["bash", "-c", "cat ~/.cache/wallpaper-switcher/state.json 2>/dev/null || echo '{}'"]
            stdout: SplitParser { onRead: line => { root._stateBuf += line } }
            onExited: {
                try {
                    var state = JSON.parse(root._stateBuf.trim() || "{}")
                    root.activeWallpapers = state
                    root._wallpapersRev++
                    console.log("WallpaperService: loaded state:", JSON.stringify(state))
                } catch(e) {
                    console.warn("WallpaperService: failed to parse state.json:", e)
                }
                root._stateBuf = ""
            }
        }

        Process {
            id: stateWriteProc
        }
    }

    Component.onCompleted: {
        scanNeeded()
        loadStateNeeded()
        monitorsNeeded()
    }
}

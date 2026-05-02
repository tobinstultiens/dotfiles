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

    // Reconcile saved state with actual monitors: remap stale entries to
    // unassigned monitors in order (e.g. DP-3 → DP-2 if DP-3 no longer exists).
    function _pruneStaleMonitors() {
        if (root.monitors.length === 0) return
        var pruned = {}
        var stale = []
        for (var m in root.activeWallpapers) {
            if (root.monitors.indexOf(m) >= 0)
                pruned[m] = root.activeWallpapers[m]
            else
                stale.push(root.activeWallpapers[m])
        }
        if (stale.length === 0) return
        // Assign orphaned wallpapers to monitors that have no wallpaper yet
        var unassigned = root.monitors.filter(m => !pruned.hasOwnProperty(m))
        for (var i = 0; i < Math.min(stale.length, unassigned.length); i++)
            pruned[unassigned[i]] = stale[i]
        root.activeWallpapers = pruned
        root._wallpapersRev++
        _saveState()
    }

    function _saveState() {
        var data = {}
        for (var m in root.activeWallpapers) data[m] = root.activeWallpapers[m]
        // stateWriteProc is accessed by ID (same QML document scope), not via _impl property
        stateWriteProc.command = [
            "python3", "-c",
            "import sys, pathlib; p = pathlib.Path.home() / '.cache/wallpaper-switcher/state.json'; " +
            "p.parent.mkdir(parents=True, exist_ok=True); p.write_text(sys.argv[1])",
            JSON.stringify(data)
        ]
        stateWriteProc.running = true
    }

    property var _impl: Item {

        Connections {
            target: root
            function onScanNeeded()      { scanProc.running = true }
            function onLoadStateNeeded() { stateReadProc.running = true }
            function onMonitorsNeeded()  { monitorsProc.running = true }
        }

        Timer {
            id: monitorsRetry
            interval: 500
            onTriggered: monitorsProc.running = true
        }

        Process {
            id: monitorsProc
            command: ["bash", "-c", "hyprctl monitors -j 2>/dev/null"]
            stdout: SplitParser { onRead: line => { root._monitorsBuf += line } }
            onExited: {
                try {
                    var mons = JSON.parse(root._monitorsBuf)
                    if (!Array.isArray(mons) || mons.length === 0) throw new Error("empty")
                    root.monitors = mons.map(m => m.name)
                    root._pruneStaleMonitors()
                } catch(e) {
                    // Hyprland IPC may not be ready yet — retry once
                    monitorsRetry.start()
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
                    root._pruneStaleMonitors()
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

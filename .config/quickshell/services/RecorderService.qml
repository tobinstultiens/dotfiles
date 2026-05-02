pragma Singleton
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    property bool   running: false
    property bool   paused:  false
    property int    elapsed: 0      // seconds since recording started
    property string outputPath: ""

    signal startRequested()
    signal stopRequested()
    signal pauseRequested()

    function start()       { if (!running) startRequested() }
    function stop()        { if (running)  stopRequested()  }
    function togglePause() { if (running)  pauseRequested() }

    function formatElapsed() {
        const h = Math.floor(elapsed / 3600)
        const m = Math.floor((elapsed % 3600) / 60)
        const s = elapsed % 60
        if (h > 0) return h + ":" + (m<10?"0":"") + m + ":" + (s<10?"0":"") + s
        return m + ":" + (s<10?"0":"") + s
    }

    property var _impl: Item {

        Connections {
            target: root
            function onStartRequested() {
                recordProc.running = true
                root.running = true
                root.elapsed = 0
                elapsedTimer.start()
            }
            function onStopRequested()  { stopProc.running  = true }
            function onPauseRequested() {
                pauseProc.running = true
                root.paused = !root.paused
            }
        }

        // Main recording process — killed by stopProc sending SIGINT
        Process {
            id: recordProc
            command: ["bash", "-c",
                      "mkdir -p \"$HOME/Videos\" && " +
                      "gpu-screen-recorder -w screen -f 60 -c mp4 -o \"$HOME/Videos/\" 2>/dev/null"]
            onExited: {
                root.running = false
                root.paused  = false
                root.elapsed = 0
                elapsedTimer.stop()
                root.outputPath = ""
            }
        }

        // SIGINT causes gpu-screen-recorder to finalize and write the file
        Process {
            id: stopProc
            command: ["bash", "-c", "pkill -INT -x gpu-screen-recorder 2>/dev/null; true"]
        }

        // SIGUSR1 toggles pause in gpu-screen-recorder
        Process {
            id: pauseProc
            command: ["bash", "-c", "pkill -USR1 -x gpu-screen-recorder 2>/dev/null; true"]
        }

        Timer {
            id: elapsedTimer
            interval: 1000
            repeat: true
            onTriggered: if (root.running && !root.paused) root.elapsed++
        }
    }
}

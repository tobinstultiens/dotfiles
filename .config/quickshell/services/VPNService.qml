pragma Singleton
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    // PIA (via piactl daemon)
    property bool   piaConnected: false
    property string piaState:     "Disconnected"  // raw piactl connectionstate
    property string piaRegion:    ""
    property string piaIp:        ""

    // Tailscale (user-space, no sudo)
    property bool   tsConnected: false
    property string tsIp:        ""

    property bool anyConnected: piaConnected || tsConnected

    property string _piaBuf:    ""
    property string _piaRgnBuf: ""
    property string _piaIpBuf:  ""
    property string _tsBuf:     ""

    function piaToggle() {
        if (root.piaConnected) {
            piaDisconnectProc.running = true
        } else {
            piaConnectProc.running = true
        }
    }

    function tsToggle() {
        if (root.tsConnected) {
            tsDownProc.running = true
        } else {
            tsUpProc.running = true
        }
    }

    property var _impl: Item {

        Timer {
            interval: 10000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: {
                piaCheckProc.running = true
                tsCheckProc.running  = true
            }
        }

        // PIA: connection state
        Process {
            id: piaCheckProc
            command: ["bash", "-c", "piactl get connectionstate 2>/dev/null || echo Disconnected"]
            stdout: SplitParser { onRead: line => { root._piaBuf += line.trim() } }
            onExited: {
                var state = root._piaBuf.trim()
                root.piaState     = state
                root.piaConnected = state === "Connected"
                root._piaBuf      = ""
                // Fetch region + IP only when connected
                if (root.piaConnected) {
                    piaRegionProc.running = true
                    piaIpProc.running     = true
                } else {
                    root.piaRegion = ""
                    root.piaIp     = ""
                }
            }
        }

        Process {
            id: piaRegionProc
            command: ["bash", "-c", "piactl get region 2>/dev/null || true"]
            stdout: SplitParser { onRead: line => { root._piaRgnBuf += line.trim() } }
            onExited: { root.piaRegion = root._piaRgnBuf.trim(); root._piaRgnBuf = "" }
        }

        Process {
            id: piaIpProc
            command: ["bash", "-c", "piactl get vpnip 2>/dev/null || true"]
            stdout: SplitParser { onRead: line => { root._piaIpBuf += line.trim() } }
            onExited: { root.piaIp = root._piaIpBuf.trim(); root._piaIpBuf = "" }
        }

        Process {
            id: piaConnectProc
            command: ["piactl", "connect"]
            onExited: piaCheckProc.running = true
        }

        Process {
            id: piaDisconnectProc
            command: ["piactl", "disconnect"]
            onExited: { root.piaConnected = false; root.piaRegion = ""; root.piaIp = ""; piaCheckProc.running = true }
        }

        // Tailscale
        Process {
            id: tsCheckProc
            command: ["bash", "-c", "tailscale status --json 2>/dev/null || echo '{}'"]
            stdout: SplitParser { onRead: line => { root._tsBuf += line } }
            onExited: {
                try {
                    var s = JSON.parse(root._tsBuf.trim() || "{}")
                    root.tsConnected = s.BackendState === "Running"
                    var self = s.Self
                    root.tsIp = (self && self.TailscaleIPs && self.TailscaleIPs.length > 0)
                                ? self.TailscaleIPs[0] : ""
                } catch(e) {
                    root.tsConnected = false
                    root.tsIp = ""
                }
                root._tsBuf = ""
            }
        }

        Process {
            id: tsUpProc
            command: ["tailscale", "up"]
            onExited: tsCheckProc.running = true
        }

        Process {
            id: tsDownProc
            command: ["tailscale", "down"]
            onExited: { root.tsConnected = false; tsCheckProc.running = true }
        }
    }

    Component.onCompleted: {
        piaCheckProc.running = true
        tsCheckProc.running  = true
    }
}

pragma Singleton
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    // WireGuard
    property bool   wgConnected:  false
    property string wgInterface:  ""   // active interface from 'wg show interfaces'
    property string wgConfigName: "wg0" // config to bring up (from /etc/wireguard/)

    // Tailscale
    property bool   tsConnected: false
    property string tsIp:        ""

    property bool anyConnected: wgConnected || tsConnected

    property string _wgBuf: ""
    property string _tsBuf: ""
    property string _cfgBuf: ""

    function wgToggle() {
        if (root.wgConnected) {
            wgDownProc.running = true
        } else {
            wgUpProc.running = true
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

        // Poll both VPNs every 10s
        Timer {
            interval: 10000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: {
                wgCheckProc.running = true
                tsCheckProc.running = true
            }
        }

        // Discover WireGuard config name from /etc/wireguard/ on startup
        Process {
            id: wgConfigProc
            command: ["bash", "-c",
                "ls /etc/wireguard/*.conf 2>/dev/null | head -1 | sed 's|.*/||;s|\\.conf$||'"]
            stdout: SplitParser { onRead: line => { root._cfgBuf += line.trim() } }
            onExited: {
                var name = root._cfgBuf.trim()
                if (name.length > 0) root.wgConfigName = name
                root._cfgBuf = ""
            }
        }

        // Detect active WireGuard interface
        Process {
            id: wgCheckProc
            command: ["bash", "-c", "wg show interfaces 2>/dev/null || true"]
            stdout: SplitParser { onRead: line => { root._wgBuf += line.trim() } }
            onExited: {
                var iface = root._wgBuf.trim().split(/\s+/).filter(s => s.length > 0)[0] || ""
                root.wgInterface  = iface
                root.wgConnected  = iface !== ""
                root._wgBuf = ""
            }
        }

        // Detect Tailscale state
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

        // WireGuard up/down — requires sudoers NOPASSWD for wg-quick
        Process {
            id: wgUpProc
            command: ["bash", "-c", "sudo wg-quick up " + root.wgConfigName + " 2>/dev/null"]
            onExited: wgCheckProc.running = true
        }

        Process {
            id: wgDownProc
            command: ["bash", "-c",
                "sudo wg-quick down " + (root.wgInterface || root.wgConfigName) + " 2>/dev/null"]
            onExited: { root.wgConnected = false; wgCheckProc.running = true }
        }

        // Tailscale — user-space, no sudo required
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
        wgConfigProc.running = true
        wgCheckProc.running  = true
        tsCheckProc.running  = true
    }
}

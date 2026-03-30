import Quickshell.Io
import QtQuick

Item {
    id: root

    property real   cpuPercent:  0.0
    property real   ramUsedGb:   0.0
    property real   ramTotalGb:  0.0
    property real   ramPercent:  0.0
    property string diskUsed:    "?"
    property string diskTotal:   "?"
    property real   diskPercent: 0.0
    property string uptime:      "?"
    property bool   active:      false

    Timer {
        interval: 3000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cpuProc.running  = true
            ramProc.running  = true
            diskProc.running = true
            upProc.running   = true
        }
    }

    // CPU: two /proc/stat snapshots 400ms apart, compute delta
    Process {
        id: cpuProc
        command: [
            "bash", "-c",
            "T1=$(awk '/^cpu /{s=0; for(i=2;i<=NF;i++) s+=$i; print s}' /proc/stat); " +
            "I1=$(awk '/^cpu /{print $5+$6}' /proc/stat); " +
            "sleep 0.4; " +
            "T2=$(awk '/^cpu /{s=0; for(i=2;i<=NF;i++) s+=$i; print s}' /proc/stat); " +
            "I2=$(awk '/^cpu /{print $5+$6}' /proc/stat); " +
            "dt=$((T2-T1)); di=$((I2-I1)); " +
            "if [ $dt -gt 0 ]; then echo $(( (dt-di)*100/dt )); else echo 0; fi"
        ]
        stdout: SplitParser {
            onRead: line => { root.cpuPercent = parseFloat(line) || 0 }
        }
    }

    // RAM: parse /proc/meminfo
    Process {
        id: ramProc
        command: [
            "bash", "-c",
            "awk '/^MemTotal/{t=$2} /^MemAvailable/{a=$2} " +
            "END{used=t-a; printf \"%.1f %.1f %.0f\", used/1024/1024, t/1024/1024, (used/t)*100}' " +
            "/proc/meminfo"
        ]
        stdout: SplitParser {
            onRead: line => {
                const p = line.trim().split(" ")
                root.ramUsedGb  = parseFloat(p[0]) || 0
                root.ramTotalGb = parseFloat(p[1]) || 0
                root.ramPercent = parseFloat(p[2]) || 0
            }
        }
    }

    // Disk: df on /
    Process {
        id: diskProc
        command: ["bash", "-c", "df -h / | awk 'NR==2{print $3, $2, $5}'"]
        stdout: SplitParser {
            onRead: line => {
                const p = line.trim().split(" ")
                root.diskUsed    = p[0] || "?"
                root.diskTotal   = p[1] || "?"
                root.diskPercent = parseFloat((p[2] || "0").replace("%", "")) || 0
            }
        }
    }

    // Uptime: from /proc/uptime
    Process {
        id: upProc
        command: [
            "bash", "-c",
            "awk '{s=int($1); d=int(s/86400); h=int((s%86400)/3600); m=int((s%3600)/60); " +
            "if(d>0) printf \"%dd %dh %dm\",d,h,m; else printf \"%dh %dm\",h,m}' /proc/uptime"
        ]
        stdout: SplitParser {
            onRead: line => { root.uptime = line.trim() }
        }
    }
}

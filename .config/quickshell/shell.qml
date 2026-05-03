//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import QtQuick
import "modules/sidebar"
import "modules/bar"
import "modules/wallpaper"
import "modules/notifications"
import "modules/osd"
import Qs

ShellRoot {
    // Shared state for the bar power menu
    QtObject { id: pms; property bool open: false }

    // Shared state for the wallpaper picker
    QtObject { id: wps; property bool open: false }

    // Shared state for the media popup
    QtObject { id: mps; property bool open: false; property real popupX: 8 }

    // Shared state for the VPN popup
    QtObject { id: vps; property bool open: false; property real popupX: 8 }

    // Shared state for bar popouts
    QtObject { id: aps; property bool open: false; property real popupX: 8 }  // audio
    QtObject { id: bts; property bool open: false; property real popupX: 8 }  // bluetooth
    QtObject { id: nps; property bool open: false; property real popupX: 8 }  // network

    // One bar per screen
    Variants {
        model: Quickshell.screens
        Bar {
            required property var modelData
            screen: modelData
            powerMenuState:   pms
            mediaPopupState:  mps
            vpnPopupState:    vps
            audioPopupState:  aps
            btPopupState:     bts
            networkPopupState: nps
        }
    }

    // Power menu overlay dropdown
    BarPowerMenu {
        open: pms.open
        onCloseRequested: pms.open = false
    }

    // Media player popup
    BarMediaPopup {
        open: mps.open
        popupX: mps.popupX
        onCloseRequested: mps.open = false
    }

    // VPN popup
    BarVPNPopup {
        open: vps.open
        popupX: vps.popupX
        onCloseRequested: vps.open = false
    }

    // Audio popup
    BarAudioPopup {
        open: aps.open
        popupX: aps.popupX
        onCloseRequested: aps.open = false
    }

    // Bluetooth popup
    BarBluetoothPopup {
        open: bts.open
        popupX: bts.popupX
        onCloseRequested: bts.open = false
    }

    // Network popup
    BarNetworkPopup {
        open: nps.open
        popupX: nps.popupX
        onCloseRequested: nps.open = false
    }

    // One wallpaper renderer per screen — Layer.Background, dual-image crossfade
    Variants {
        model: Quickshell.screens
        WallpaperBackground {
            required property var modelData
            screen: modelData
        }
    }

    WallpaperPicker {
        open: wps.open
        onCloseRequested: wps.open = false
    }

    // Notification toasts — top-right below bar
    NotifPopups {}

    // On-screen display for volume/brightness
    OSD { id: osd }

    Sidebar {
        id: sidebar
    }

    // ── IPC Handlers ────────────────────────────────────────────────────

    IpcHandler {
        target: "osd"

        // Called from hyprland.conf brightness keybinds:
        //   qs ipc call osd brightness up
        //   qs ipc call osd brightness down
        function brightness(direction: string): void {
            var step = 10
            var cur = 50  // fallback; brightnessctl reads actual value
            var cmd = direction === "up" ? "brightnessctl s 10%+" : "brightnessctl s 10%-"
            brightnessProc.command = ["bash", "-c", cmd + " && brightnessctl g && brightnessctl m"]
            brightnessProc.running = true
        }
    }

    // Reads brightness after setting it, then shows OSD
    Process {
        id: brightnessProc
        property string _buf: ""
        stdout: SplitParser { onRead: line => { brightnessProc._buf += line + "\n" } }
        onExited: {
            var lines = _buf.trim().split("\n").filter(l => l.length > 0)
            if (lines.length >= 2) {
                var cur = parseInt(lines[lines.length - 2]) || 0
                var max = parseInt(lines[lines.length - 1]) || 1
                osd.showBrightness(Math.round(cur / max * 100))
            }
            _buf = ""
        }
    }

    IpcHandler {
        target: "recorder"
        function toggle(): void {
            if (RecorderService.running) RecorderService.stop()
            else RecorderService.start()
        }
        function start(): void { RecorderService.start() }
        function stop(): void  { RecorderService.stop()  }
    }

    IpcHandler {
        target: "wallpaper"
        function toggle(): void { wps.open = !wps.open }
        function show(): void   { wps.open = true }
        function hide(): void   { wps.open = false }
    }

    IpcHandler {
        target: "sidebar"
        function toggle(): void { sidebar.open = !sidebar.open }
        function show(): void   { sidebar.open = true }
        function hide(): void   { sidebar.open = false }
    }
}

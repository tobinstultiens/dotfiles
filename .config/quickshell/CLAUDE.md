# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Running and Reloading

```bash
# Start the shell
qs

# Reload after changes (QuickShell watches files and hot-reloads automatically)
# No manual reload needed — edits to .qml files take effect on save

# Toggle the sidebar via IPC
qs ipc call sidebar toggle
qs ipc call sidebar show
qs ipc call sidebar hide
```

The Hyprland keybind `Super+I` is mapped to `qs ipc call sidebar toggle`.

## Architecture

**Entry point:** `shell.qml` — declares the `ShellRoot`, instantiates `SystemInfo` and `Sidebar`, and registers the `IpcHandler` for the sidebar toggle.

**Colors:** `Colors.qml` is a `pragma Singleton` registered in `qmldir`. All sidebar files import it with `import "../.." 1.0` and reference colors as `Colors.base`, `Colors.blue`, etc. (Catppuccin Mocha palette). To add a new color, add it to `Colors.qml` — no other registration needed.

**System data:** `services/SystemInfo.qml` is a plain `Item` (not a QuickShell Singleton) instantiated once in `shell.qml` and passed as `required property var sysInfo` through `Sidebar → SystemStats`. It polls CPU/RAM/Disk/Uptime every 3s via shell processes, but only when `active: sidebar.open`.

**Sidebar panel:** `modules/sidebar/Sidebar.qml` is a `PanelWindow` anchored to the right edge. Key behaviours:
- `visible` is tied to `open || hideTimer.running` so the Wayland surface is destroyed after the 260ms slide-out animation, preventing invisible input blocking.
- `exclusionMode: ExclusionMode.Ignore` — overlays apps, does not push them.
- `PowerButtons` is pinned outside the `Flickable` at the bottom; all other widgets scroll.

**Polling pattern:** Widgets that own their own timers (`NetworkWidget`, `BrightnessWidget`) accept `required property bool active` and gate their timers on it. `Sidebar.qml` passes `active: root.open`. This stops all polling when the sidebar is closed.

**Network speed** (`NetworkWidget`): reads `/proc/net/dev` once per 2s tick and computes a delta against the previous stored values — no `sleep` subprocess. Counters reset on `ifaceNameChanged`.

**Widgets that auto-hide:** `BrightnessWidget` hides itself when `maxBrightness === 0` (no backlight device). `BatteryWidget` hides itself when `UPower.displayDevice` is null or not a laptop battery.

## Adding a New Widget

1. Create `modules/sidebar/MyWidget.qml`
2. Add `import "../.." 1.0` for `Colors` access
3. If the widget polls, add `property bool active: false` and gate timers on it
4. Add it to the `Column` inside `Sidebar.qml`'s `Flickable`, passing `active: root.open` if needed

## Known QML Pitfalls in This Codebase

- `Layout.fillWidth` only works inside `RowLayout`/`ColumnLayout`, not inside `Row`/`Column`. Use spacer `Item` with explicit width instead.
- `PanelWindow` uses `implicitWidth` not `width` (setting `width` emits a deprecation warning).
- `Behavior on transform.xTranslation` is invalid — use an intermediate `property real` and put the `Behavior` on that.
- Subdirectory QML files cannot see root-level types without `import "../.." 1.0`. The version suffix is required for the `qmldir` singleton registration to work.
- QuickShell's `Singleton {}` root type does NOT expose properties by type name to subdirectory files. Use `pragma Singleton` + `qmldir` registration instead (as done for `Colors.qml`).

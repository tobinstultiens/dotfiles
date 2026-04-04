# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Testing Changes

**Always test by running `qs` after making changes** and check for errors before reporting done:

```bash
qs 2>&1 &
QS_PID=$!
sleep 4
kill $QS_PID
wait $QS_PID 2>/dev/null
```

Look for `ERROR` lines in the output — a failed load prints `Failed to load configuration` and a cause chain. Fix all errors before finishing. Hot-reload handles most edits automatically, but `//@ pragma UseQApplication` and `qmldir` changes require a full restart.

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

**Entry point:** `shell.qml` — declares the `ShellRoot`, creates one `Bar` per screen via `Variants`, creates `Sidebar`, and registers the `IpcHandler`. Has `//@ pragma UseQApplication` at the top (required for `QsMenuAnchor.open()` to work).

**Colors:** `Colors.qml` is a `pragma Singleton` registered in `Qs/qmldir`. All files import it with `import Qs` and reference colors as `Colors.base`, `Colors.blue`, etc. (Catppuccin Mocha palette). This works because `QML_IMPORT_PATH=/home/tobins/.config/quickshell` is set in Hyprland's env config, and `Qs/qmldir` registers the singletons under the module name `Qs`.

**System data:** `services/SystemInfo.qml` is a `pragma Singleton` registered in `Qs/qmldir` (`singleton SystemInfo 1.0 services/SystemInfo.qml`). Any file with `import "../.." 1.0` can use `SystemInfo.cpuPercent`, `SystemInfo.ramPercent`, etc. directly. It polls CPU/RAM/Disk/Uptime/Temp every 3s always-on (bar needs continuous data). Root is `QtObject` (required for `pragma Singleton` — `Item` root fails silently).

**Sidebar panel:** `modules/sidebar/Sidebar.qml` is a `PanelWindow` anchored to the right edge, width 400px. Key behaviours:
- `visible` is tied to `open || hideTimer.running` so the Wayland surface is destroyed after the 260ms slide-out animation, preventing invisible input blocking.
- `exclusionMode: ExclusionMode.Ignore` — overlays apps, does not push them.
- Content is a plain `Column` (not scrollable). `PowerButtons` is pinned at the bottom outside the column.

**Polling pattern:** Widgets that own their own timers (`NetworkWidget`, `BrightnessWidget`) accept `required property bool active` and gate their timers on it. `Sidebar.qml` passes `active: root.open`. This stops all polling when the sidebar is closed.

**Network speed** (`NetworkWidget`): reads `/proc/net/dev` once per 2s tick and computes a delta against the previous stored values — no `sleep` subprocess. Counters reset on `ifaceNameChanged`.

**Widgets that auto-hide:** `BrightnessWidget` hides itself when `maxBrightness === 0` (no backlight device). `BatteryWidget` hides itself when `UPower.displayDevice` is null or not a laptop battery.

## Bar Layout (right to left within the right Row)

All pills use the inline `Pill` component in `Bar.qml` with a shared `iconSize: 16` default.

| Widget | File | Notes |
|--------|------|-------|
| UPowerDevice ×3 | `UPowerDevice.qml` | Bluetooth headset, headphones, mouse — hidden when device absent |
| VolumeWidget | `VolumeWidget.qml` | `volume%  󰋋/󰋎` — click to mute, scroll to adjust |
| MicWidget | `MicWidget.qml` | `volume%  󰍬/󰍭` — click to mute, scroll to adjust |
| CPU pill | inline in `Bar.qml` | nf-md-chip icon, blue |
| RAM pill | inline in `Bar.qml` | nf-md-memory icon, mauve |
| Temp pill | inline in `Bar.qml` | nf-md-thermometer / nf-md-fire (≥80°C), peach/red |
| ClockPill | inline in `Bar.qml` | `HH:mm`, seconds not shown in bar |
| TrayWidget | `TrayWidget.qml` | wrapped in a pill; right-click uses `QsMenuAnchor` |

**WindowTitle** is anchored to `horizontalCenter: parent.horizontalCenter` on the `PanelWindow` directly (outside the `RowLayout`) so it is always screen-centred regardless of left/right section widths.

**BarMediaWidget** priority: Spotify (if playing) → any playing player → Spotify (if paused with track info) → any player. Shows `value%  icon` format. Fixed pill width is not used — pill is dynamic width, text truncated to 40 chars.

## System Tray

`TrayWidget.qml` uses `QsMenuAnchor` for right-click context menus (requires `//@ pragma UseQApplication` in `shell.qml`). The `item.icon` property returns `image://icon/name` or `image://qspixmap/n/n` URLs — NOT raw icon names.

**Known broken icons and their fixes** (in `resolveIcon()` in `TrayWidget.qml`):
- `image://icon/drive-removable-media` (udiskie) → `file:///usr/share/icons/AdwaitaLegacy/32x32/devices/drive-removable-media.png`
- `image://icon/spotify-linux-*` (Spotify) → `file:///opt/spotify/icons/spotify-linux-32.png`

SVG files do not load via `file://` in `IconImage` — always use PNG for file-based fallbacks.

## Sidebar Widgets

| Widget | File | Section header accent |
|--------|----|---|
| Clock + calendar | `ClockCalendar.qml` | — (no header) |
| System stats | `SystemStats.qml` | Blue |
| Network | `NetworkWidget.qml` | Green |
| Brightness | `BrightnessWidget.qml` | Yellow |
| Media player | `MediaWidget.qml` | Mauve |
| Battery | `BatteryWidget.qml` | — (no header) |
| Power buttons | `PowerButtons.qml` | Red (SESSION) |

Section headers use the reusable `SectionHeader.qml` component: a 3px coloured accent bar, bold spaced label, and a hairline divider extending to the right.

The sidebar clock shows `HH:mm` at 64px and `:ss` at 36px (dimmer, baseline-aligned). It uses `SystemClock.Seconds` precision.

## Adding a New Widget

1. Create `modules/sidebar/MyWidget.qml`
2. Add `import "../.." 1.0` for `Colors` access
3. If the widget polls, add `property bool active: false` and gate timers on it
4. Add a `SectionHeader { width: parent.width; label: "MY WIDGET"; accent: Colors.blue }` at the top of its Column
5. Add it to the `Column` inside `Sidebar.qml`, passing `active: root.open` if needed

## Known QML Pitfalls in This Codebase

- `Layout.fillWidth` only works inside `RowLayout`/`ColumnLayout`, not inside `Row`/`Column`. Use spacer `Item` with explicit width instead.
- `PanelWindow` uses `implicitWidth` not `width` (setting `width` emits a deprecation warning).
- `Behavior on transform.xTranslation` is invalid — use an intermediate `property real` and put the `Behavior` on that.
- Subdirectory QML files cannot see root-level types without `import "../.." 1.0`. The version suffix is required for the `qmldir` singleton registration to work.
- QuickShell's `Singleton {}` root type does NOT expose properties by type name to subdirectory files. Use `pragma Singleton` + `qmldir` registration instead.
- `pragma Singleton` requires a `QtObject` root — using `Item` as root fails silently (type resolves to the component factory, not an instance; property access returns `undefined`). For singletons that need `Timer`/`Process` children: use a `QtObject` root with `property var _impl: Item { ... }` — the inner `Item` has the `data` default property that hosts the non-visual children naturally.
- `PanelWindow` per-monitor assignment: declare `required screen` (NOT `required property var screen`) to mark the inherited property as required without shadowing it.
- `QsMenuAnchor.open()` requires `//@ pragma UseQApplication` in the root `shell.qml` — without it, calls silently fail with an error log.
- `Text` properties like `letterSpacing` must be prefixed: `font.letterSpacing`, not bare `letterSpacing`.
- `item.icon` on `SystemTrayItem` returns a `image://` URL, not a raw icon name string — string comparisons against plain icon names will never match.

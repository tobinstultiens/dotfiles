# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Dotfiles Tracking

**Whenever a new source file is created in this repo, register it with the dotfiles tracker immediately after:**

```bash
config add <new-file-path>
```

`config` is an alias for a bare git repo managing dotfiles — it accepts all standard `git` subcommands. New files are untracked by default and must be explicitly added. Existing files are already tracked; edits to them do not require `config add`.

**Do not `config add` files under `data/`** (`data/notes.txt`, `data/todos.json`, etc.) — these are runtime-written user data, not source files.

## Knowledge Index

A comprehensive reference is maintained at [`QS_KNOWLEDGE.md`](QS_KNOWLEDGE.md). It contains:
- Complete service catalog (all 10 singletons) with properties and methods
- Full file map (all QML files including services, popups, OSD, wallpaper, notifications)
- Bar and sidebar widget order (current)
- All IPC handlers and shared state objects (`pms`, `wps`, `mps`, `vps`, `aps`, `bts`, `nps`)
- Complete external dependency table
- QuickShell API reference (which QS modules are used where)
- Hardcoded values (coordinates, paths, magic numbers)
- Color palette reference
- Known pitfalls beyond those listed here

**Keep `QS_KNOWLEDGE.md` up to date.** Whenever you add a new widget, service, IPC handler, shared state object, external dependency, hardcoded value, or discover a new pitfall or QuickShell API behavior — update the relevant section of `QS_KNOWLEDGE.md` immediately after the change. This is the primary reference for building future widgets correctly.

## Testing Changes

`qs` cannot be run in the Claude Code sandbox (no Wayland compositor). **Do not attempt to test by running `qs`** — ask the user to reload instead, or rely on QML syntax review.

Hot-reload handles most edits automatically. `//@ pragma UseQApplication` and `qmldir` changes require a full restart (`killall qs && qs &`).

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

## External Dependencies

All required tools must be installed. Missing tools cause silent failures (widgets hide or show stale data) rather than load errors.

| Tool / Resource | Required by | Purpose |
|---|---|---|
| `nmcli` | `NetworkWidget.qml`, `BarNetworkPopup.qml` | WiFi info, network list, connect/disconnect |
| `brightnessctl` | `BrightnessWidget.qml` | Read and set backlight level |
| `hyprlock` | `PowerButtons.qml` | Lock screen |
| `systemctl` | `PowerButtons.qml` | Poweroff, reboot, suspend |
| `python3` (stdlib) | `TodoService.qml`, `NotesWidget.qml`, `WallpaperService.qml`, `WlsunsetWidget.qml`, `CavaWidget.qml` | Atomic file writes; avoids shell quoting |
| `pactl` | `AudioService.qml` | Aggregate sink/source info as JSON |
| `curl` | `WeatherService.qml`, `RainService.qml` | Open-Meteo API fetches (15s timeout) |
| `piactl` daemon | `VPNService.qml` | PIA VPN control (must be running as daemon) |
| `tailscale` CLI | `VPNService.qml` | Tailscale status + up/down |
| `gpu-screen-recorder` | `RecorderService.qml` | Screen recording (SIGINT=stop, SIGUSR1=pause) |
| `cava` | `CavaWidget.qml` | Audio visualizer; PipeWire input |
| `wlsunset` | `WlsunsetWidget.qml` | Color temperature / night light |
| `hyprctl` | `WallpaperService.qml`, `WallpaperPicker.qml` | Monitor list, workspace switching |
| `pkill` | `RecorderService.qml`, `WlsunsetWidget.qml` | Signal external processes |
| JetBrainsMono Nerd Font | All widgets | Nerd-font icon glyphs — no fallback font set |

## File Map

```
shell.qml                                    Entry point; all panels, shared state objects (pms/wps/mps/vps/aps/bts/nps), 4 IPC handlers
Colors.qml                                   pragma Singleton: Catppuccin Mocha palette + pillHeight: 34
EqualizerBars.qml                            Reusable animated equalizer: property bool playing, property color barColor
CavaWidget.qml                               Reusable cava visualizer: bars, barColor, playing, barWidth, spacing
Qs/qmldir                                    Registers all 10 singletons → import Qs 1.0

services/SystemInfo.qml                      pragma Singleton: CPU/RAM/disk/uptime/temp — polls every 3s always-on
services/TodoService.qml                     pragma Singleton: todo CRUD, selectedDate, _revision counter, python3 persistence
services/WallpaperService.qml               pragma Singleton: monitor list, wallpaper scan + apply; state → ~/.cache/wallpaper-switcher/state.json
services/WeatherService.qml                 pragma Singleton: Open-Meteo weather + 5-day forecast; polls every 30 min
services/NotificationService.qml            pragma Singleton: DBus NotificationServer; keepOnReload:true; model + unread counter
services/VPNService.qml                     pragma Singleton: PIA (piactl) + Tailscale state; polls every 10s
services/RecorderService.qml               pragma Singleton: gpu-screen-recorder lifecycle; running/paused/elapsed
services/AudioService.qml                  pragma Singleton: pactl-backed sink/source list + default switching
services/RainService.qml                   pragma Singleton: Open-Meteo rain forecast (8×15min); polls every 10 min

modules/bar/Bar.qml                         PanelWindow 44px; inline Pill/ClockPill/RecordingPill/VPNPill/NetworkPill/BluetoothPill
modules/bar/WorkspacesWidget.qml            Workspace + window-icon pills, left side of bar
modules/bar/BarMediaWidget.qml              MPRIS compact pill, left side of bar; click → mps.open
modules/bar/BarPowerMenu.qml               Full-screen overlay PanelWindow; open state driven by pms.open
modules/bar/TrayWidget.qml                 SystemTray repeater with QsMenuAnchor right-click; resolveIcon() for broken icons
modules/bar/VolumeWidget.qml               PipeWire speaker volume pill; click → aps.open
modules/bar/MicWidget.qml                  Microphone volume pill; hides when source is null
modules/bar/UPowerDevice.qml              Bluetooth battery pill; hidden when device absent
modules/bar/WindowTitle.qml               Focused window title, screen-centred on PanelWindow
modules/bar/BarMediaPopup.qml             Full MPRIS popup; circular art + progress ring + radial equalizer; driven by mps.open
modules/bar/BarVPNPopup.qml               PIA + Tailscale toggle rows; driven by VPNService + vps.open
modules/bar/BarAudioPopup.qml             Sink/source device selector + volume sliders (0–150%); driven by aps.open
modules/bar/BarBluetoothPopup.qml         Bluetooth device list + enable/discover toggles; driven by bts.open
modules/bar/BarNetworkPopup.qml           nmcli WiFi scanner + connect/disconnect; driven by nps.open

modules/sidebar/Sidebar.qml               PanelWindow 400px right; 260ms slide; hideTimer 280ms; Flickable content
modules/sidebar/ClockCalendar.qml         64px HH:mm + 36px :ss; calendar grid; day tap → TodoService.selectedDate
modules/sidebar/TodoWidget.qml            Peach-accented todo list for selectedDate; uses TodoService + _revision
modules/sidebar/SystemStats.qml          CPU/RAM/disk/uptime stat rows; inline StatRow; blue header
modules/sidebar/NetworkWidget.qml        nmcli connection info + /proc/net/dev speed delta; active-gated; green header
modules/sidebar/BrightnessWidget.qml     brightnessctl slider; self-hides when maxBrightness === 0; active-gated; yellow header
modules/sidebar/WlsunsetWidget.qml       wlsunset day/night temperature sliders; config → data/wlsunset.json; yellow header
modules/sidebar/MediaWidget.qml          Full MPRIS card with album art; inline MediaBtn; mauve header
modules/sidebar/WeatherWidget.qml        Current conditions + 5-day forecast from WeatherService; green header
modules/sidebar/RainWidget.qml           2h precipitation bar chart from RainService; blue header
modules/sidebar/BatteryWidget.qml        UPower battery bar; self-hides when no laptop battery
modules/sidebar/NotifWidget.qml          Notification log from NotificationService; dismiss + clear-all; lavender header
modules/sidebar/NotesWidget.qml          Lavender-accented TextEdit; debounced 1500ms python3 save to data/notes.txt
modules/sidebar/PowerButtons.qml         Session controls; confirm/cancel state machine; inline PowerBtn; red SESSION header
modules/sidebar/SectionHeader.qml        Reusable: 3px accent bar + bold label + hairline divider

modules/notifications/NotifPopups.qml    PanelWindow top-right toast stack; ExclusionMode.Ignore
modules/notifications/NotifToast.qml    Slide-in toast; auto-dismiss; hover pauses; critical never auto-dismiss

modules/osd/OSD.qml                      WlrLayer.Overlay OSD; modes: volume/brightness/volume-app; 2s auto-hide

modules/wallpaper/WallpaperBackground.qml  WlrLayer.Background per screen; double-buffered image swap; 600ms fade
modules/wallpaper/WallpaperPicker.qml      Full-screen grid; keyboard nav (Tab/arrows/Return/Esc); driven by wps.open
modules/wallpaper/WallpaperTransition.qml  Overlay covering blank-frame flash during wallpaper switch

data/notes.txt                            Plain text; written by NotesWidget on debounce; created on first save
data/todos.json                           JSON [{id,date,text,done}]; written by TodoService on every mutation
data/wlsunset.json                        JSON {dayTemp,nightTemp,latitude,longitude}; written by WlsunsetWidget
```

## Architecture

**Entry point:** `shell.qml` declares the `ShellRoot`, creates one `Bar` per screen via `Variants`, and registers all panels and 4 `IpcHandler` targets. Has `//@ pragma UseQApplication` at the top (required for `QsMenuAnchor.open()` to work). Shared `QtObject` state objects (`pms`, `wps`, `mps`, `vps`, `aps`, `bts`, `nps`) are passed as required properties to panels that need to communicate open/close state — this avoids direct sibling `PanelWindow` dependencies.

**Qs module:** All 10 `pragma Singleton` services are registered in `Qs/qmldir`. Any file can import them with `import Qs 1.0` and reference them by type name directly. This works because `QML_IMPORT_PATH=/home/tobins/.config/quickshell` is set in Hyprland's env config.

**SystemInfo polling** runs every 3s always-on (not gated by sidebar state). The bar pills (CPU, RAM, temp) need continuous data even while the sidebar is closed.

## Services

All 10 singletons are registered in `Qs/qmldir`. Import with `import Qs 1.0` (version suffix required).

| Singleton | File | Key properties | Polling |
|---|---|---|---|
| `Colors` | `Colors.qml` | Full Catppuccin Mocha palette; `pillHeight: 34` | None (static) |
| `SystemInfo` | `services/SystemInfo.qml` | `cpuPercent`, `ramUsedGb`, `ramTotalGb`, `ramPercent`, `diskUsed`, `diskTotal`, `diskPercent`, `uptime`, `tempCelsius` | Every 3s, always-on |
| `TodoService` | `services/TodoService.qml` | `todoModel`, `selectedDate`, `_revision`; `addTodo`, `toggleTodo`, `removeTodo`, `todosForDate`, `hasTodosForDate` | On-demand |
| `WallpaperService` | `services/WallpaperService.qml` | `monitors[]`, `activeWallpapers{}`, `wallpapers[]`, `_wallpapersRev`; `apply(monitor, path)`, `activeFor(monitor)` | On-demand; signal `applyRequested` |
| `WeatherService` | `services/WeatherService.qml` | `currentTemp/Code/Wind/Humidity/Icon/Desc`, `forecast[]`, `hasData`, `loading` | Every 30 min |
| `NotificationService` | `services/NotificationService.qml` | `model` (ObjectModel), `unread`; `clearAll()`, `markRead()`; `keepOnReload: true` | Event-driven (DBus) |
| `VPNService` | `services/VPNService.qml` | `piaConnected/State/Region/Ip`, `tsConnected/Ip`, `anyConnected`; `piaToggle()`, `tsToggle()` | Every 10s |
| `RecorderService` | `services/RecorderService.qml` | `running`, `paused`, `elapsed`; `formatElapsed()`; signals: `startRequested`, `stopRequested`, `pauseRequested` | On-demand |
| `AudioService` | `services/AudioService.qml` | `sinks[]`, `sources[]` ({name,description,isDefault}), `loading`; `refresh()`, `setSink(name)`, `setSource(name)` | On-demand |
| `RainService` | `services/RainService.qml` | `readings[]` (8×{minutes,mmh}), `hasData`, `hasRain`, `maxMmh` | Every 10 min |

**Temperature source:** `SystemInfo.qml` reads `/sys/devices/pci0000:00/0000:00:18.3/hwmon/hwmon*/temp1_input` — AMD CPU die temperature. On Intel or other hardware this path will not exist and `tempCelsius` stays `0`. Adjust `tempProc.command` to deploy on non-AMD hardware.

## Persistent Data

The `data/` directory holds all runtime-written state.

| File | Format | Written by | Read by |
|---|---|---|---|
| `data/notes.txt` | Plain text (supports `TextEdit.MarkdownText` rendering) | `NotesWidget.qml` — debounced 1500ms after last keystroke | `NotesWidget.qml` on `Component.onCompleted` |
| `data/todos.json` | JSON array: `[{id, date, text, done}, ...]`; `date` is `"yyyy-MM-dd"` | `TodoService.qml` — on every `addTodo`/`toggleTodo`/`removeTodo` | `TodoService.qml` on `Component.onCompleted` |
| `data/wlsunset.json` | JSON `{dayTemp, nightTemp, latitude, longitude}` | `WlsunsetWidget.qml` — on slider change | `WlsunsetWidget.qml` on `Component.onCompleted` |

Both files are written via `python3 -c "import sys,pathlib; p=pathlib.Path.home()/'.config/quickshell/data/<file>'; p.parent.mkdir(parents=True,exist_ok=True); p.write_text(sys.argv[1])"`. This is preferred over bash redirection because `write_text` is effectively atomic and auto-creates `data/` on first run.

## Bar Layout (right to left within the right Row)

All pills use the inline `Pill` component in `Bar.qml` with a shared `iconSize: 16` default.

| Widget | File | Notes |
|---|---|---|
| RecordingPill | inline in `Bar.qml` | Pulsing red dot; opacity 0.4 when paused; hidden when not recording |
| VPNPill | inline in `Bar.qml` | PIA / Tailscale / both; click → `vps.open` |
| NetworkPill | inline in `Bar.qml` | WiFi/Ethernet SSID; polls every 15s; click → `nps.open` |
| BluetoothPill | inline in `Bar.qml` | Connected device count + batteries; click → `bts.open` |
| UPowerDevice ×3 | `UPowerDevice.qml` | Bluetooth headset, headphones, mouse — hidden when device absent |
| VolumeWidget | `VolumeWidget.qml` | `volume%  󰋋/󰋎` — click to mute/`aps.open`, scroll to adjust |
| MicWidget | `MicWidget.qml` | `volume%  󰍬/󰍭` — click to mute, scroll to adjust; hides when source null |
| Weather pill | inline in `Bar.qml` | Icon + temp from WeatherService |
| CPU pill | inline in `Bar.qml` | nf-md-chip icon, blue |
| RAM pill | inline in `Bar.qml` | nf-md-memory icon, mauve |
| Temp pill | inline in `Bar.qml` | nf-md-thermometer / nf-md-fire (≥80°C), peach/red |
| ClockPill | inline in `Bar.qml` | `HH:mm`, seconds not shown in bar |
| TrayWidget | `TrayWidget.qml` | wrapped in a pill; right-click uses `QsMenuAnchor` |

**Left side of bar:**

| Widget | File | Notes |
|---|---|---|
| WorkspacesWidget | `WorkspacesWidget.qml` | Workspace pills + window icons; `appIcon()` maps class names → nerd-font glyphs |
| BarMediaWidget | `BarMediaWidget.qml` | MPRIS compact pill; uses hardcoded `#1DB954` (Spotify green) when Spotify is playing |

**WindowTitle** is anchored to `horizontalCenter: parent.horizontalCenter` on the `PanelWindow` directly (outside the `RowLayout`) so it is always screen-centred regardless of left/right section widths.

**BarMediaWidget** priority: Spotify (if playing) → any playing player → Spotify (if paused with track info) → any player. Shows `value%  icon` format. Pill is dynamic width, text truncated to 40 chars.

## System Tray

`TrayWidget.qml` uses `QsMenuAnchor` for right-click context menus (requires `//@ pragma UseQApplication` in `shell.qml`). The `item.icon` property returns `image://icon/name` or `image://qspixmap/n/n` URLs — NOT raw icon names.

**Known broken icons and their fixes** (in `resolveIcon()` in `TrayWidget.qml`):
- `image://icon/drive-removable-media` (udiskie) → `file:///usr/share/icons/AdwaitaLegacy/32x32/devices/drive-removable-media.png`
- `image://icon/spotify-linux-*` (Spotify) → `file:///opt/spotify/icons/spotify-linux-32.png`

SVG files do not load via `file://` in `IconImage` — always use PNG for file-based fallbacks.

## Sidebar Widgets

| Widget | File | Section header accent |
|---|---|---|
| Clock + calendar | `ClockCalendar.qml` | — (no header) |
| System stats | `SystemStats.qml` | Blue |
| Network | `NetworkWidget.qml` | Green |
| Brightness | `BrightnessWidget.qml` | Yellow |
| Night light | `WlsunsetWidget.qml` | Yellow |
| Media player | `MediaWidget.qml` | Mauve |
| Weather | `WeatherWidget.qml` | Green |
| Rain forecast | `RainWidget.qml` | Blue |
| Battery | `BatteryWidget.qml` | — (no header) |
| Notifications | `NotifWidget.qml` | Lavender |
| Notes | `NotesWidget.qml` | Lavender |
| Power buttons | `PowerButtons.qml` | Red (SESSION) |

Section headers use the reusable `SectionHeader.qml` component: a 3px coloured accent bar, bold spaced label, and a hairline divider extending to the right.

The sidebar clock shows `HH:mm` at 64px and `:ss` at 36px (dimmer, baseline-aligned). It uses `SystemClock.Seconds` precision.

## Adding a New Widget

1. Create `modules/sidebar/MyWidget.qml`
2. Add `import "../.." 1.0` for `Colors` access (version suffix is required)
3. If the widget polls, add `required property bool active` and set `timer.running: root.active`
4. Add a `SectionHeader { width: parent.width; label: "MY WIDGET"; accent: Colors.blue }` at the top of its Column
5. Add it to the `Column` inside `Sidebar.qml`, passing `active: root.open` if needed
6. If the widget reads from `TodoService.todoModel`, include a binding that reads `TodoService._revision` so it re-evaluates on mutations

## Patterns and Conventions

**Inline `component` declarations** — private sub-components only used within one file are declared with `component Name: BaseType { ... }` inside the parent (e.g., `Pill`/`ClockPill` in `Bar.qml`, `StatRow` in `SystemStats.qml`, `PowerBtn` in `PowerButtons.qml`, `MediaBtn` in `MediaWidget.qml`). These cannot be used from other files. Extract to a named `.qml` file only when sharing across files.

**`QtObject + _impl` singleton pattern** — `pragma Singleton` requires a `QtObject` root, but `Timer`/`Process` need a parent with a `data` default property (`Item`). Solution: declare `property var _impl: Item { ... }` inside the `QtObject`. The inner `Item` hosts all `Timer`/`Process` children. See `SystemInfo.qml:7`, `TodoService.qml:5`. Never use `Item` as a singleton root — it fails silently and property access returns `undefined`.

**Reactive `_revision` counter** — `TodoService._revision` increments on every mutation. Any QML binding that reads it becomes a reactive dependency and re-evaluates when the model changes. Use this to push `ListModel` mutations across component boundaries — direct bindings to `ListModel` contents don't propagate like regular properties. See `TodoWidget.qml` and `ClockCalendar.qml`.

**Confirmation state machine for destructive actions** — `PowerButtons.qml` uses `property string pendingAction: ""`. First tap calls `confirm(cmd)` (sets `pendingAction`, shows Confirm/Cancel UI); second tap calls `execute(cmd)` (clears `pendingAction`, runs the command). Reuse this pattern for any irreversible action.

**Active-gated polling** — sidebar widgets with their own timers accept `required property bool active` and set `running: root.active` on their `Timer`s. `Sidebar.qml` passes `active: root.open`, stopping all subprocess calls when the sidebar is closed. `SystemInfo` intentionally does NOT gate — bar requires continuous data.

**Auto-hiding widgets** — hardware-conditional widgets set `visible: <condition>`; the `Column` collapses the gap because `implicitHeight` returns `0` when `visible: false`. `BrightnessWidget` hides when `maxBrightness === 0`; `BatteryWidget` hides when no laptop battery; `MicWidget` hides when `source` is null.

**Sidebar surface lifetime** — `Sidebar.qml` sets `visible: open || hideTimer.running` so the Wayland surface is destroyed after the slide-out animation. The `hideTimer` interval is 280ms (20ms margin above the 260ms animation) to prevent the surface from being destroyed mid-animation.

## Known QML Pitfalls in This Codebase

- `Layout.fillWidth` only works inside `RowLayout`/`ColumnLayout`, not inside `Row`/`Column`. Use a spacer `Item` with explicit width instead.
- `PanelWindow` uses `implicitWidth` not `width` — setting `width` emits a deprecation warning. (`Bar.qml:10`, `Sidebar.qml:22`)
- `Behavior on transform.xTranslation` is invalid — use an intermediate `property real slideX` and put the `Behavior` on that. (`Sidebar.qml:50-55`)
- Subdirectory QML files cannot see root-level types without `import "../.." 1.0`. The version suffix is required for the `qmldir` singleton registration to work. (every `modules/**/*.qml`)
- QuickShell's `Singleton {}` root type does NOT expose properties by type name to subdirectory files. Use `pragma Singleton` + `qmldir` registration instead.
- `pragma Singleton` requires a `QtObject` root — using `Item` as root fails silently (property access returns `undefined`). For singletons that need `Timer`/`Process` children, use the `_impl: Item { ... }` pattern. (`SystemInfo.qml:7`, `TodoService.qml:5`)
- `PanelWindow` per-monitor assignment: declare `required screen` (NOT `required property var screen`) to mark the inherited property as required without shadowing it. (`Bar.qml:10`)
- `QsMenuAnchor.open()` requires `//@ pragma UseQApplication` in `shell.qml` — without it, calls silently fail with an error log. (`shell.qml:1`, `TrayWidget.qml`)
- `Text` font properties must be prefixed: `font.letterSpacing`, not bare `letterSpacing`. (`SectionHeader.qml:29`)
- `item.icon` on `SystemTrayItem` returns an `image://` URL, not a raw icon name string — string comparisons against plain icon names will never match. (`TrayWidget.qml:13-42`)

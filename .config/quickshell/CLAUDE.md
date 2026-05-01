# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Dotfiles Tracking

**Whenever a new source file is created in this repo, register it with the dotfiles tracker immediately after:**

```bash
config add <new-file-path>
```

`config` is an alias for a bare git repo managing dotfiles — it accepts all standard `git` subcommands. New files are untracked by default and must be explicitly added. Existing files are already tracked; edits to them do not require `config add`.

**Do not `config add` files under `data/`** (`data/notes.txt`, `data/todos.json`, etc.) — these are runtime-written user data, not source files.

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
| `nmcli` (NetworkManager) | `NetworkWidget.qml` | Connection type, SSID, signal strength |
| `brightnessctl` | `BrightnessWidget.qml` | Read and set backlight level |
| `hyprlock` | `PowerButtons.qml` | Lock screen |
| `systemctl` | `PowerButtons.qml` | Poweroff, reboot, suspend |
| `python3` (stdlib) | `TodoService.qml`, `NotesWidget.qml` | Atomic file writes to `data/` |
| JetBrainsMono Nerd Font | All widgets | Nerd-font icon glyphs — no fallback font set |

## File Map

```
shell.qml                             Entry point: ShellRoot, one Bar per screen, Sidebar, IpcHandler; pms QtObject shared between Bar and BarPowerMenu
Colors.qml                            pragma Singleton: Catppuccin Mocha palette + pillHeight constant
EqualizerBars.qml                     Reusable animated equalizer: property bool playing, property color barColor
Qs/qmldir                             Module registration: Colors, SystemInfo, TodoService → import Qs
services/SystemInfo.qml               pragma Singleton: CPU/RAM/disk/uptime/temp — polls every 3s always-on
services/TodoService.qml              pragma Singleton: todo CRUD, selectedDate, _revision counter, python3 persistence
modules/bar/Bar.qml                   PanelWindow 44px; inline Pill + ClockPill components; right Row + WindowTitle
modules/bar/WorkspacesWidget.qml      Workspace + window-icon pills, left side of bar
modules/bar/BarMediaWidget.qml        MPRIS compact pill, left side of bar
modules/bar/BarPowerMenu.qml          Full-screen overlay PanelWindow; open state driven by pms.open in shell.qml
modules/bar/TrayWidget.qml            SystemTray repeater with QsMenuAnchor right-click; resolveIcon() for broken icons
modules/bar/VolumeWidget.qml          PipeWire speaker volume pill
modules/bar/MicWidget.qml             Microphone volume pill; hides when source is null
modules/bar/UPowerDevice.qml          Bluetooth battery pill; hidden when device absent
modules/bar/WindowTitle.qml           Focused window title, screen-centred on PanelWindow
modules/sidebar/Sidebar.qml           PanelWindow 400px right edge; slide animation; widget Column; footer PowerButtons
modules/sidebar/ClockCalendar.qml     Large clock, calendar grid; tapping a day sets TodoService.selectedDate
modules/sidebar/TodoWidget.qml        Peach-accented todo list for the calendar-selected date; uses TodoService
modules/sidebar/SystemStats.qml       CPU/RAM/disk/uptime stat rows; inline StatRow component
modules/sidebar/NetworkWidget.qml     nmcli connection info + /proc/net/dev speed delta; active-gated
modules/sidebar/BrightnessWidget.qml  brightnessctl slider; self-hides when maxBrightness === 0; active-gated
modules/sidebar/MediaWidget.qml       Full MPRIS card with album art; inline MediaBtn component
modules/sidebar/BatteryWidget.qml     UPower battery bar; self-hides when no laptop battery
modules/sidebar/NotesWidget.qml       Lavender-accented TextEdit; debounced python3 save to data/notes.txt
modules/sidebar/PowerButtons.qml      Session controls with confirm/cancel state machine; inline PowerBtn
modules/sidebar/SectionHeader.qml     Reusable: 3px accent bar + bold label + hairline divider
data/notes.txt                        Plain text; written by NotesWidget, created on first save
data/todos.json                       JSON array of todo objects; written by TodoService on every mutation
```

## Architecture

**Entry point:** `shell.qml` declares the `ShellRoot`, creates one `Bar` per screen via `Variants`, creates `Sidebar` and `BarPowerMenu`, and registers the `IpcHandler`. Has `//@ pragma UseQApplication` at the top (required for `QsMenuAnchor.open()` to work). A shared `QtObject { id: pms; property bool open }` is passed to both `Bar` and `BarPowerMenu` — this avoids a direct parent-child dependency between two sibling `PanelWindow` instances.

**Qs module:** `Colors`, `SystemInfo`, and `TodoService` are `pragma Singleton` types registered in `Qs/qmldir`. Any file can import them with `import Qs` and reference them by type name directly. This works because `QML_IMPORT_PATH=/home/tobins/.config/quickshell` is set in Hyprland's env config.

**SystemInfo polling** runs every 3s always-on (not gated by sidebar state). The bar pills (CPU, RAM, temp) need continuous data even while the sidebar is closed.

## Services

All three singletons are registered in `Qs/qmldir`. Import with `import Qs`.

| Singleton | File | Key properties | Polling |
|---|---|---|---|
| `Colors` | `Colors.qml` | Full Catppuccin Mocha palette; `pillHeight: 34` | None (static) |
| `SystemInfo` | `services/SystemInfo.qml` | `cpuPercent`, `ramUsedGb`, `ramTotalGb`, `ramPercent`, `diskUsed`, `diskTotal`, `diskPercent`, `uptime`, `tempCelsius` | Every 3s, always-on |
| `TodoService` | `services/TodoService.qml` | `todoModel`, `selectedDate`, `_revision`; functions: `addTodo`, `toggleTodo`, `removeTodo`, `todosForDate`, `hasTodosForDate` | On-demand (load on startup, save on mutation) |

**Temperature source:** `SystemInfo.qml` reads `/sys/devices/pci0000:00/0000:00:18.3/hwmon/hwmon*/temp1_input` — AMD CPU die temperature. On Intel or other hardware this path will not exist and `tempCelsius` stays `0`. Adjust `tempProc.command` to deploy on non-AMD hardware.

## Persistent Data

The `data/` directory holds all runtime-written state.

| File | Format | Written by | Read by |
|---|---|---|---|
| `data/notes.txt` | Plain text (supports `TextEdit.MarkdownText` rendering) | `NotesWidget.qml` — debounced 1500ms after last keystroke | `NotesWidget.qml` on `Component.onCompleted` |
| `data/todos.json` | JSON array: `[{id, date, text, done}, ...]`; `date` is `"yyyy-MM-dd"` | `TodoService.qml` — on every `addTodo`/`toggleTodo`/`removeTodo` | `TodoService.qml` on `Component.onCompleted` |

Both files are written via `python3 -c "import sys,pathlib; p=pathlib.Path.home()/'.config/quickshell/data/<file>'; p.parent.mkdir(parents=True,exist_ok=True); p.write_text(sys.argv[1])"`. This is preferred over bash redirection because `write_text` is effectively atomic and auto-creates `data/` on first run.

## Bar Layout (right to left within the right Row)

All pills use the inline `Pill` component in `Bar.qml` with a shared `iconSize: 16` default.

| Widget | File | Notes |
|---|---|---|
| UPowerDevice ×3 | `UPowerDevice.qml` | Bluetooth headset, headphones, mouse — hidden when device absent |
| VolumeWidget | `VolumeWidget.qml` | `volume%  󰋋/󰋎` — click to mute, scroll to adjust |
| MicWidget | `MicWidget.qml` | `volume%  󰍬/󰍭` — click to mute, scroll to adjust; hides when source null |
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
| Media player | `MediaWidget.qml` | Mauve |
| Notes | `NotesWidget.qml` | Lavender |
| Battery | `BatteryWidget.qml` | — (no header) |
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

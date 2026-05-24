# QS_KNOWLEDGE.md — QuickShell Living Reference

This is a **living document**. It must be kept current — stale information here causes incorrect widget code. Update it immediately whenever any of the following happen:

- A new widget, service, popup, or module is added
- A service, IPC handler, shared state object, or external dependency changes
- A new QuickShell API is used for the first time
- A QuickShell upgrade introduces new APIs, changes existing ones, or fixes known bugs
- A new pitfall or unexpected QML/QS behavior is discovered
- A hardcoded value (coordinate, path, magic number) changes

**How to discover new QuickShell API information:**
- Primary source: [QuickShell docs](https://quickshell.outfoxxed.me/docs/) — covers all built-in types, properties, signals
- Secondary: read existing `.qml` files in this repo that already use an API you want to learn
- For QS internals/edge cases: [QuickShell source](https://git.outfoxxed.me/outfoxxed/quickshell) — the QML type registrations are the ground truth
- When upgrading QuickShell (`qs --version` to check): read the release notes and check for renamed/removed properties before assuming existing code still works
- If a widget silently breaks after a QS update, check: property renames, signal signature changes, enum moves, module restructuring

---

## Services Registry

All 10 singletons are registered in `Qs/qmldir`. Import with `import Qs 1.0` (version suffix required in subdirectories).

| Singleton | File | Key properties / methods | Polling |
|---|---|---|---|
| `Colors` | `Colors.qml` | Full Catppuccin Mocha palette (see Color Palette section); `pillHeight: 34` | None (static) |
| `SystemInfo` | `services/SystemInfo.qml` | `cpuPercent`, `ramUsedGb`, `ramTotalGb`, `ramPercent`, `diskUsed`, `diskTotal`, `diskPercent`, `uptime`, `tempCelsius` | Every 3s, always-on |
| `TodoService` | `services/TodoService.qml` | `todoModel`, `selectedDate`, `_revision`; `addTodo(date,text)`, `toggleTodo(id)`, `removeTodo(id)`, `todosForDate(date)`, `hasTodosForDate(date)` | On-demand (load on startup, save on mutation) |
| `WallpaperService` | `services/WallpaperService.qml` | `monitors[]`, `activeWallpapers{}`, `wallpapers[]` ({path,name}), `_wallpapersRev`; `apply(monitor, path)`, `activeFor(monitor)` | On-demand; signal `applyRequested(monitor, path)` |
| `WeatherService` | `services/WeatherService.qml` | `currentTemp`, `currentCode`, `currentWind`, `currentHumidity`, `currentIcon`, `currentDesc`, `forecast[]` ({date,code,high,low,icon,desc}), `hasData`, `loading` | Every 30 min |
| `NotificationService` | `services/NotificationService.qml` | `model` (ObjectModel of Notification), `unread`; `clearAll()`, `markRead()`; `keepOnReload: true` | Event-driven (DBus) |
| `VPNService` | `services/VPNService.qml` | `piaConnected`, `piaState`, `piaRegion`, `piaIp`, `tsConnected`, `tsIp`, `anyConnected`; `piaToggle()`, `tsToggle()` | Every 10s |
| `RecorderService` | `services/RecorderService.qml` | `running`, `paused`, `elapsed`; `formatElapsed()`; signals: `startRequested`, `stopRequested`, `pauseRequested` | On-demand |
| `AudioService` | `services/AudioService.qml` | `sinks[]` ({name,description,isDefault}), `sources[]` ({name,description,isDefault}), `loading`; `refresh()`, `setSink(name)`, `setSource(name)` | On-demand (`refresh()`) |
| `RainService` | `services/RainService.qml` | `readings[]` (8 entries × {minutes,mmh}), `hasData`, `hasRain`, `maxMmh` (clamped min 0.5) | Every 10 min |

**Temperature source:** `SystemInfo.qml` reads `/sys/devices/pci0000:00/0000:00:18.3/hwmon/hwmon*/temp1_input` — AMD CPU die temp. Stays `0` on non-AMD hardware; adjust `tempProc.command` to deploy elsewhere.

**NotificationService:** `unread` is manually incremented on each new notification, never auto-decremented on dismiss — call `markRead()` explicitly.

---

## Shell Architecture

`shell.qml` is the entry point. It declares all panels and passes shared state objects as required properties to avoid direct sibling `PanelWindow` dependencies.

### Shared State Objects (QtObject)

| ID | Controls | Passed to |
|---|---|---|
| `pms` | `open: bool` — power menu | `Bar`, `BarPowerMenu` |
| `wps` | `open: bool` — wallpaper picker | `Bar` (button), `WallpaperPicker` |
| `mps` | `open: bool` — media popup | `Bar`, `BarMediaPopup` |
| `vps` | `open: bool` — VPN popup | `Bar`, `BarVPNPopup` |
| `aps` | `open: bool` — audio popup | `Bar`, `BarAudioPopup` |
| `bts` | `open: bool` — bluetooth popup | `Bar`, `BarBluetoothPopup` |
| `nps` | `open: bool` — network popup | `Bar`, `BarNetworkPopup` |

### IPC Handlers

| Target | Commands | Notes |
|---|---|---|
| `sidebar` | `toggle`, `show`, `hide` | Hyprland keybind `Super+I` → `toggle` |
| `osd` | `volumeApp(pct, muted, app)`, `brightness(direction)` | OSD overlay |
| `recorder` | `toggle`, `start`, `stop` | Drives `RecorderService` |
| `wallpaper` | `toggle`, `show`, `hide` | Controls `WallpaperPicker` overlay |

### Panels Declared in shell.qml

- `Bar` × N (one per screen via `Variants { model: Quickshell.screens }`)
- `Sidebar`
- `BarPowerMenu`
- `BarMediaPopup`, `BarVPNPopup`, `BarAudioPopup`, `BarBluetoothPopup`, `BarNetworkPopup`
- `WallpaperBackground` × N (one per screen)
- `WallpaperPicker`
- `NotifPopups`
- `OSD`

---

## Complete File Map

```
shell.qml                                    Entry point; all panels, shared state objects (pms/wps/mps/vps/aps/bts/nps), 4 IPC handlers
Colors.qml                                   pragma Singleton: Catppuccin Mocha palette + pillHeight: 34
EqualizerBars.qml                            Reusable animated equalizer; property bool playing, property color barColor
CavaWidget.qml                               Reusable cava audio visualizer; properties: bars, barColor, playing, barWidth, spacing
Qs/qmldir                                    Registers all 10 singletons → import Qs 1.0

services/SystemInfo.qml                      pragma Singleton: CPU/RAM/disk/uptime/temp — polls every 3s always-on
services/TodoService.qml                     pragma Singleton: todo CRUD, selectedDate, _revision counter, python3 persistence
services/WallpaperService.qml               pragma Singleton: monitor list, wallpaper scan + apply, state persisted to ~/.cache/wallpaper-switcher/state.json
services/WeatherService.qml                 pragma Singleton: Open-Meteo weather + 5-day forecast; polls every 30 min; coords lat=51.4 lon=5.5
services/NotificationService.qml            pragma Singleton: DBus NotificationServer; keepOnReload:true; model + unread counter
services/VPNService.qml                     pragma Singleton: PIA (piactl) + Tailscale state; polls every 10s
services/RecorderService.qml               pragma Singleton: gpu-screen-recorder lifecycle; running/paused/elapsed
services/AudioService.qml                  pragma Singleton: pactl-backed sink/source list + default switching
services/RainService.qml                   pragma Singleton: Open-Meteo rain forecast (8×15min); polls every 10 min; coords lat=51.4 lon=5.5

modules/bar/Bar.qml                         PanelWindow 44px; inline Pill/ClockPill/RecordingPill/VPNPill/NetworkPill/BluetoothPill; left+right rows + WindowTitle
modules/bar/WorkspacesWidget.qml            Workspace + window-icon pills; appIcon() nerd-font glyph map
modules/bar/BarMediaWidget.qml              MPRIS compact pill; Spotify green #1DB954; click → mps.open
modules/bar/BarPowerMenu.qml               Full-screen overlay; open driven by pms.open
modules/bar/TrayWidget.qml                 SystemTray repeater; QsMenuAnchor right-click; resolveIcon() for broken icons
modules/bar/VolumeWidget.qml               PipeWire speaker volume pill; click → aps.open
modules/bar/MicWidget.qml                  Microphone volume pill; hides when source null
modules/bar/UPowerDevice.qml              Bluetooth battery pill; hidden when device absent
modules/bar/WindowTitle.qml               Focused window title, screen-centred on PanelWindow
modules/bar/BarMediaPopup.qml             Full MPRIS popup; circular art + progress ring + radial equalizer; player selector pills
modules/bar/BarVPNPopup.qml               PIA + Tailscale toggle rows; driven by VPNService
modules/bar/BarAudioPopup.qml             Sink/source device selector + per-device volume sliders (0–150%); driven by AudioService + Pipewire
modules/bar/BarBluetoothPopup.qml         Bluetooth device list; enable/discover toggles; BlueZ via Quickshell.Bluetooth
modules/bar/BarNetworkPopup.qml           nmcli WiFi scanner; network list + connect/disconnect; rescan button

modules/sidebar/Sidebar.qml               PanelWindow 400px right; 260ms slide animation; hideTimer 280ms; Flickable content + PowerButtons footer
modules/sidebar/ClockCalendar.qml         64px clock + :ss at 36px; calendar grid; day tap → TodoService.selectedDate
modules/sidebar/TodoWidget.qml            Peach-accented todo list for selectedDate; uses TodoService + _revision
modules/sidebar/SystemStats.qml          CPU/RAM/disk/uptime stat rows; inline StatRow component; blue header
modules/sidebar/NetworkWidget.qml        nmcli connection info + /proc/net/dev speed delta; active-gated; green header
modules/sidebar/BrightnessWidget.qml     brightnessctl slider; self-hides when maxBrightness === 0; active-gated; yellow header
modules/sidebar/WlsunsetWidget.qml       wlsunset day/night temperature sliders; config persisted to data/wlsunset.json; yellow header
modules/sidebar/MediaWidget.qml          Full MPRIS card with album art; inline MediaBtn; mauve header
modules/sidebar/WeatherWidget.qml        Current conditions + 5-day forecast from WeatherService; green header
modules/sidebar/RainWidget.qml           Bar chart of 2h rain forecast from RainService; blue header
modules/sidebar/BatteryWidget.qml        UPower battery bar; self-hides when no laptop battery
modules/sidebar/NotifWidget.qml          Notification log from NotificationService; dismiss per-item or clear-all; lavender header
modules/sidebar/NotesWidget.qml          Lavender-accented TextEdit; debounced 1500ms python3 save to data/notes.txt
modules/sidebar/PowerButtons.qml         Session controls; confirm/cancel state machine; inline PowerBtn; red SESSION header
modules/sidebar/SectionHeader.qml        Reusable: 3px accent bar + bold spaced label + hairline divider

modules/notifications/NotifPopups.qml    PanelWindow top-right toast stack; ExclusionMode.Ignore; Repeater over NotificationService.model
modules/notifications/NotifToast.qml    Slide-in toast; auto-dismiss (expireTimeout or 8s default); hover pauses; critical never auto-dismiss

modules/osd/OSD.qml                      PanelWindow WlrLayer.Overlay; modes: volume/brightness/volume-app; 2s auto-hide; driven by IPC + Pipewire

modules/wallpaper/WallpaperBackground.qml  WlrLayer.Background per screen; double-buffered image swap; 600ms fade transition
modules/wallpaper/WallpaperPicker.qml      Full-screen grid picker; keyboard nav (Tab=monitor, arrows=image, Return=apply, Esc=close); workspace switching
modules/wallpaper/WallpaperTransition.qml  Overlay that covers blank-frame flash during hyprpaper switch; 120+220+380ms fade sequence

data/notes.txt                            Plain text; written by NotesWidget on debounce; created on first save
data/todos.json                           JSON [{id,date,text,done}]; written by TodoService on every mutation
data/wlsunset.json                        JSON {dayTemp,nightTemp,latitude,longitude}; written by WlsunsetWidget
```

---

## Bar Layout

### Right side (right to left)

| Widget | File | Notes |
|---|---|---|
| Power menu button | inline `Bar.qml` | Opens `pms.open` |
| TrayWidget | `TrayWidget.qml` | Wrapped in pill; right-click `QsMenuAnchor` |
| ClockPill | inline `Bar.qml` | `HH:mm`; click → sidebar |
| Temp pill | inline `Bar.qml` | nf-md-thermometer / nf-md-fire (≥80°C), peach/red |
| RAM pill | inline `Bar.qml` | nf-md-memory, mauve |
| CPU pill | inline `Bar.qml` | nf-md-chip, blue |
| Weather pill | inline `Bar.qml` | Icon + temp from WeatherService |
| MicWidget | `MicWidget.qml` | Hides when source null |
| VolumeWidget | `VolumeWidget.qml` | Click → `aps.open`; click-to-mute; scroll to adjust |
| UPowerDevice ×3 | `UPowerDevice.qml` | Headset, headphones, mouse; hidden when absent |
| BluetoothPill | inline `Bar.qml` | Connected device count + type icons + batteries; click → `bts.open` |
| NetworkPill | inline `Bar.qml` | WiFi/Ethernet SSID; polls every 15s via nmcli; click → `nps.open` |
| VPNPill | inline `Bar.qml` | PIA / Tailscale / both; click → `vps.open` |
| RecordingPill | inline `Bar.qml` | Pulsing red dot; opacity 0.4 when paused; hidden when not recording |

### Left side

| Widget | File | Notes |
|---|---|---|
| WorkspacesWidget | `WorkspacesWidget.qml` | Workspace pills + window icons |
| BarMediaWidget | `BarMediaWidget.qml` | MPRIS compact pill; Spotify → any playing → Spotify paused → any; truncated 40 chars; click → `mps.open` |

**WindowTitle** is anchored to `horizontalCenter: parent.horizontalCenter` on the `PanelWindow` directly (outside the `RowLayout`) — always screen-centred.

---

## Sidebar Widget Order

| Widget | File | Section header accent | Notes |
|---|---|---|---|
| Clock + calendar | `ClockCalendar.qml` | — (no header) | 64px HH:mm + 36px :ss; day tap → TodoService.selectedDate |
| System stats | `SystemStats.qml` | Blue | CPU/RAM/disk/uptime |
| Network | `NetworkWidget.qml` | Green | nmcli + /proc/net/dev speeds; active-gated |
| Brightness | `BrightnessWidget.qml` | Yellow | brightnessctl slider; self-hides when maxBrightness===0 |
| Night light | `WlsunsetWidget.qml` | Yellow | wlsunset day/night temp sliders; restarts wlsunset on change |
| Media player | `MediaWidget.qml` | Mauve | Full MPRIS card + album art |
| Weather | `WeatherWidget.qml` | Green | Current conditions + 5-day forecast |
| Rain forecast | `RainWidget.qml` | Blue | 2h bar chart; hidden when no data |
| Battery | `BatteryWidget.qml` | — (no header) | UPower; self-hides when no laptop battery |
| Notifications | `NotifWidget.qml` | Lavender | Notification log; dismiss + clear-all |
| Notes | `NotesWidget.qml` | Lavender | TextEdit; debounced python3 save |
| Power buttons | `PowerButtons.qml` | Red (SESSION) | confirm/cancel state machine |

---

## External Dependencies

| Tool / Resource | Required by | Purpose |
|---|---|---|
| `nmcli` | `NetworkWidget.qml`, `BarNetworkPopup.qml` | WiFi info, network list, connect/disconnect |
| `brightnessctl` | `BrightnessWidget.qml` | Read and set backlight level |
| `hyprlock` | `PowerButtons.qml` | Lock screen |
| `systemctl` | `PowerButtons.qml` | Poweroff, reboot, suspend |
| `python3` (stdlib) | `TodoService.qml`, `NotesWidget.qml`, `WallpaperService.qml`, `WlsunsetWidget.qml`, `CavaWidget.qml` | Atomic file writes; avoids shell quoting issues |
| `pactl` | `AudioService.qml` | Aggregate sink/source info as JSON |
| `curl` | `WeatherService.qml`, `RainService.qml` | Open-Meteo API; 15s timeout |
| `piactl` daemon | `VPNService.qml` | PIA VPN control (must be running as daemon) |
| `tailscale` CLI | `VPNService.qml` | Tailscale status + up/down |
| `gpu-screen-recorder` | `RecorderService.qml` | Screen recording (SIGINT=stop, SIGUSR1=pause/resume) |
| `cava` | `CavaWidget.qml` | Audio visualizer; PipeWire input; raw output with `;` delimiter |
| `wlsunset` | `WlsunsetWidget.qml` | Color temperature / night light |
| `hyprctl` | `WallpaperService.qml`, `WallpaperPicker.qml` | Monitor list, workspace switching |
| `pkill` | `RecorderService.qml`, `WlsunsetWidget.qml` | Send signals to external processes |
| JetBrainsMono Nerd Font | All widgets | Nerd-font icon glyphs; no fallback font set |

---

## QuickShell API Reference

This section documents every QS API used in this config with enough detail to use it correctly. Update this section whenever a new QS API is introduced or a known behavior changes (e.g., after a QuickShell upgrade).

### Core

**`ShellRoot`** — root element of `shell.qml`. Contains all top-level panels and shared state.

**`PanelWindow`** (`import Quickshell`)
- Wayland layer-shell window. Use `implicitWidth`/`implicitHeight`, NOT `width`/`height` (deprecated).
- Key properties: `screen` (required for per-monitor), `anchors`, `margins`, `exclusionMode`, `WlrLayershell.layer`, `WlrLayershell.namespace`
- Default layer: `WlrLayer.Top`. For background use `WlrLayer.Background`; for always-on-top overlays use `WlrLayer.Overlay`.
- `ExclusionMode.Auto` — reserves space equal to `anchors` + `margins` (used by Bar, Sidebar).
- `ExclusionMode.Ignore` — window exists but doesn't push other windows (used by NotifPopups, OSD).
- Per-monitor: declare `required screen` on the `PanelWindow` (NOT `required property var screen` — that shadows the inherited property). Pass via `Variants`.

**`Variants`** (`import Quickshell`)
- Instantiates a component once per item in `model`. Used in `shell.qml` to create one `Bar` and one `WallpaperBackground` per screen.
- `model: Quickshell.screens` gives all connected Wayland outputs.
- The delegate receives each item as a required property with the same name as the model type (e.g., `required screen`).

**`IpcHandler`** (`import Quickshell`)
- Registers a named target for `qs ipc call <target> <function> [args...]`.
- `target: "name"` — the string used in the CLI call.
- Functions are declared as regular QML functions inside the `IpcHandler` body.
- Arguments arrive as strings; parse manually if numeric.

**`SystemClock`** (`import Quickshell`)
- Provides current time as a bindable property.
- `precision: SystemClock.Seconds` — updates every second (used in sidebar clock).
- `precision: SystemClock.Minutes` — updates every minute (sufficient for bar clock).
- Properties: `hours`, `minutes`, `seconds`, `time` (JS Date).

---

### Quickshell.Io

**`Process`** (`import Quickshell.Io`)
- Manages an external subprocess. Can be long-running or one-shot.
- `command: ["executable", "arg1", ...]` — command and args as a list (no shell expansion; use `["bash", "-c", "..."]` for shell features).
- `running: bool` — set to `true` to start, `false` to stop (sends SIGTERM). Becomes `false` automatically when the process exits.
- `stdout` — connect to a `SplitParser` via `parser: proc.stdout` or use the `onRead` callback.
- `stdin.write(text)` — write to the process's stdin.
- `onExited(code, status)` — fires when process exits; `code` is the exit code.
- Does NOT use a shell by default — wrap in `["bash", "-c", "..."]` to use pipes, redirects, `||`, etc.

**`SplitParser`** (`import Quickshell.Io`)
- Splits streamed output by a delimiter and fires `onRead(data)` for each chunk.
- `splitMarker: "\n"` — splits on newlines (default and most common usage).
- `splitMarker: ";"` — used by `CavaWidget` to parse semicolon-delimited cava output.
- Connect to a `Process` via `parser: proc.stdout` or as a child of the `Process`.
- `onRead(data)` — called for each complete chunk (without the delimiter).
- Buffer strategy: accumulate partial lines in a `property string _buf`, append in `onRead`, then parse when a sentinel line or known terminator arrives.

---

### Quickshell.Wayland

**`WlrLayershell`** (`import Quickshell.Wayland`) — attached property on `PanelWindow`
- `WlrLayershell.layer` — `WlrLayer.Background | Bottom | Top | Overlay`
- `WlrLayershell.namespace` — string name shown in compositor logs (useful for debugging).
- `WlrLayershell.exclusionMode` — same as `PanelWindow.exclusionMode` (one or the other; prefer `PanelWindow.exclusionMode`).

---

### Quickshell.Services.Pipewire

`import Quickshell.Services.Pipewire`

**`Pipewire`** (global singleton)
- `Pipewire.defaultAudioSink` — current default output device (`PwNode`); can be null.
- `Pipewire.defaultAudioSource` — current default input device (`PwNode`); can be null.
- `Pipewire.sinks` / `Pipewire.sources` — ObjectModel of all devices.

**`PwObjectTracker`**
- Tracks the lifecycle of a specific PipeWire object so bindings to it don't break when the object disappears.
- `objects: [Pipewire.defaultAudioSink]` — pass the object(s) to track.
- Access the tracked object through the tracker; do not bind directly to `Pipewire.defaultAudioSink` in long-lived UI.

**`PwNode`** (audio device)
- `audio.volume` — 0.0 to 1.5 (>1.0 = software amplification).
- `audio.muted` — bool; settable.
- `name` — internal PipeWire node name (e.g., `alsa_output.pci-0000:00:1f.3.analog-stereo`).
- All `.audio` sub-properties can be null if the node isn't an audio node — guard with `if (node && node.audio)`.

---

### Quickshell.Services.Mpris

`import Quickshell.Services.Mpris`

**`Mpris`** (global singleton)
- `Mpris.players` — ObjectModel of all active MPRIS players. Iterate with `.values` array.
- Players appear/disappear dynamically as media apps open/close.

**`MprisPlayer`**
- `identity` — human-readable app name (e.g., `"Spotify"`, `"mpv"`).
- `isPlaying` — bool.
- `trackTitle`, `trackArtist`, `trackAlbum` — current track metadata (may be empty).
- `trackArtUrl` — URL string for album art (may be empty or `file://` or `http://`).
- `position` — playback position in seconds (float); not reactive — poll with a timer or bind to `positionChanged`.
- `length` — track length in seconds; `0` if unknown.
- `lengthSupported` — bool; if false, `length` is meaningless.
- `canTogglePlaying`, `canGoNext`, `canGoPrevious` — capability flags; check before showing buttons.
- `positionChanged()` — call this to force a re-read of `position` (it's not reactive by itself).
- Settable: `shuffle`, `loopStatus`, `volume` (0.0–1.0).

---

### Quickshell.Services.Notifications

`import Quickshell.Services.Notifications`

**`NotificationServer`**
- Implements the freedesktop DBus notification daemon protocol.
- `keepOnReload: true` — keeps the DBus name registered across hot-reloads (prevents apps losing the daemon).
- `actionsSupported: true` — advertises action button support to senders.
- `trackedNotifications` — ObjectModel of current `Notification` objects.
- Only one notification daemon can hold the DBus name at a time — mako/dunst must not be running.

**`Notification`**
- `appName`, `appIcon`, `summary`, `body` — standard notification fields.
- `urgency` — `NotificationUrgency.Low | Normal | Critical`.
- `expireTimeout` — milliseconds until auto-dismiss (`-1` = never, `0` = server default).
- `actions` — list of `{identifier, text}` objects; `identifier === "default"` is the click-card action.
- `dismiss()` — removes the notification from the model.
- `invokeAction(identifier)` — triggers an action by its identifier string.

**`NotificationUrgency`** enum: `Low`, `Normal`, `Critical`

---

### Quickshell.Bluetooth

`import Quickshell.Bluetooth`

**`Bluetooth`** (global singleton)
- `Bluetooth.defaultAdapter` — the primary Bluetooth adapter (`BluetoothAdapter`); can be null if no BT hardware.
- `Bluetooth.devices` — ObjectModel of all known devices (paired and nearby).

**`BluetoothAdapter`**
- `enabled` — bool; settable (toggle BT on/off).
- `discovering` — bool; settable (start/stop device scan).
- `powered` — bool; physical power state.

**`BluetoothDevice`**
- `name`, `address` — device identity.
- `connected` — bool; **directly settable** — assigning `true`/`false` triggers connect/disconnect.
- `paired` — bool.
- `battery`, `batteryAvailable` — charge percentage and whether the battery level is known.
- `icon` — string hint (e.g., `"audio-headphones"`, `"input-mouse"`); used to pick display icon.
- `state` — `BluetoothDeviceState` enum.

**`BluetoothDeviceState`** enum: `Disconnected`, `Connecting`, `Connected`, `Disconnecting`

---

### Quickshell.SystemTray

`import Quickshell` (SystemTray is part of the core module)

**`SystemTray`** (global singleton)
- `SystemTray.items` — ObjectModel of all tray items.

**`SystemTrayItem`**
- `icon` — returns an `image://icon/<name>` or `image://qspixmap/<w>/<h>` URL, **not** a plain icon name. String comparison against icon names never works.
- `tooltip` — `{title, description}` object.
- `menu` — `QsMenu` object for the context menu.
- `activate()` — left-click action.

**`QsMenuAnchor`**
- Anchors a tray item's context menu to a visual element.
- `menu: item.menu` — assign the tray item's menu.
- `anchor.window: parentWindow` — the `PanelWindow` that contains it.
- `open()` — show the menu. **Requires `//@ pragma UseQApplication` in `shell.qml`** — without it, calls silently fail.

---

### Quickshell.UPower (Battery / BT Device Battery)

`import Quickshell.Services.UPower` (or accessed via the `UPower` singleton)

Used in `UPowerDevice.qml` and `BatteryWidget.qml`. Add detail here when working with UPower directly.

---

### Key Behavioral Notes (version-agnostic)

These are behaviors of the QuickShell framework itself — not specific to this config. Document new ones here as they're discovered.

- **Hot-reload** — QuickShell watches `.qml` files and reloads automatically on save. `//@ pragma UseQApplication` changes and `qmldir` edits require a full restart (`killall qs && qs &`).
- **`pragma Singleton` root must be `QtObject`** — using `Item` as singleton root compiles but silently returns `undefined` for all property accesses.
- **`required screen` vs `required property var screen`** — the former marks the inherited property as required; the latter shadows it with a new property and breaks per-screen assignment.
- **`PanelWindow.implicitWidth`** — setting `width` directly on a `PanelWindow` emits a deprecation warning and may be ignored; always use `implicitWidth`.
- **`Behavior` on initial value** — assigning a property value before its `Behavior` is evaluated (e.g., at declaration time) does not trigger the animation. Use this to set a start position, then animate to the target in `Component.onCompleted`.
- **ObjectModel `.values`** — QuickShell ObjectModels (Mpris.players, Bluetooth.devices, etc.) expose their contents as a `.values` JS array property. This array is recreated on each access — avoid calling it in tight loops.
- **`Variants` delegate screen binding** — in `Variants { model: Quickshell.screens }`, the delegate must declare `required screen` to receive the screen object. The property name must match the model's element type name exactly.
- **IPC argument types** — all `qs ipc call` arguments arrive as strings in QML. Parse with `parseInt()` / `parseFloat()` / comparison as needed.
- **`SplitParser` and long-running processes** — if the process writes partial lines (no trailing newline), `onRead` won't fire until the delimiter appears. Buffer in `_buf` and handle the final chunk in `onExited` if needed.

---

## Hardcoded Values

| Value | Location | Notes |
|---|---|---|
| Weather/rain coordinates: `lat=51.4, lon=5.5` | `WeatherService.qml`, `RainService.qml` | Amsterdam area |
| Night-light coordinates: `lat=51.2, lon=5.7` | `WlsunsetWidget.qml` | Near Amsterdam |
| Wallpaper scan directory: `$HOME/Pictures/Wallpapers` | `WallpaperService.qml` | |
| Wallpaper state: `~/.cache/wallpaper-switcher/state.json` | `WallpaperService.qml` | Not under `~/.config` |
| Wlsunset config: `~/.config/quickshell/data/wlsunset.json` | `WlsunsetWidget.qml` | |
| Recording output: `$HOME/Videos` | `RecorderService.qml` | Created on first record |
| Cava config: `/tmp/cava_qs_{bars}.conf` | `CavaWidget.qml` | Uses `/tmp` directly, not `$TMPDIR` |
| Bar height: `44px` | `Bar.qml` | Referenced as magic `48` in NotifPopups offset |
| Sidebar width: `400px` | `Sidebar.qml` | |
| Slide animation: `260ms` | `Sidebar.qml` | hideTimer is 280ms (20ms margin) |
| Spotify accent: `#1DB954` | `BarMediaWidget.qml`, `BarMediaPopup.qml` | Hardcoded green |

---

## Color Palette (Catppuccin Mocha)

All colors accessible as `Colors.<name>` after `import Qs 1.0`.

| Property | Hex | Role |
|---|---|---|
| `base` | `#1e1e2e` | App background |
| `mantle` | `#181825` | Slightly darker background |
| `crust` | `#11111b` | Darkest background |
| `surface0` | `#313244` | |
| `surface1` | `#45475a` | |
| `surface2` | `#585b70` | |
| `overlay0` | `#6c7086` | Muted / dimmed |
| `overlay1` | `#7f849c` | |
| `overlay2` | `#9399b2` | |
| `subtext0` | `#a6adc8` | Secondary text |
| `subtext1` | `#bac2de` | |
| `text` | `#cdd6f4` | Primary text |
| `lavender` | `#b4befe` | NotesWidget, NotifWidget headers |
| `blue` | `#89b4fa` | SystemStats header, CPU pill |
| `sapphire` | `#74c7ec` | |
| `sky` | `#89dceb` | |
| `teal` | `#94e2d5` | |
| `green` | `#a6e3a1` | NetworkWidget, WeatherWidget headers |
| `yellow` | `#f9e2af` | BrightnessWidget, WlsunsetWidget headers |
| `peach` | `#fab387` | TodoWidget header |
| `maroon` | `#eba0ac` | |
| `red` | `#f38ba8` | PowerButtons header, recording indicator |
| `mauve` | `#cba6f7` | MediaWidget header, RAM pill, MPRIS default accent |
| `pink` | `#f5c2e7` | |
| `flamingo` | `#f2cdcd` | |
| `rosewater` | `#f5e0dc` | |

`Colors.pillHeight` = `34` (used for all pill heights in the bar).

---

## Patterns and Conventions

**Singleton pattern** — `pragma Singleton` requires `QtObject` root. For singletons needing `Timer`/`Process`, declare `property var _impl: Item { ... }` inside the `QtObject`. The inner `Item` hosts all `Timer`/`Process` children. Never use `Item` as singleton root — fails silently. See `SystemInfo.qml:7`, `TodoService.qml:5`.

**Inline component declarations** — private sub-components declared with `component Name: BaseType { ... }` inside the parent file. Cannot be used from other files. Extract to a named `.qml` file only for cross-file sharing.

**Reactive `_revision` counter** — `TodoService._revision` increments on every mutation. Any binding that reads it re-evaluates when the model changes. Use this pattern (not direct `ListModel` bindings) to push mutations across component boundaries. `WallpaperService._wallpapersRev` uses the same pattern for object mutation reactivity.

**Confirmation state machine** — `PowerButtons.qml` uses `property string pendingAction: ""`. First tap: `confirm(cmd)` sets `pendingAction` and shows Confirm/Cancel. Second tap: `execute(cmd)` runs the command and clears `pendingAction`. Reuse for any irreversible action.

**Active-gated polling** — sidebar widgets accept `required property bool active`; set `timer.running: root.active`. `Sidebar.qml` passes `active: root.open`. `SystemInfo` is intentionally NOT gated — bar always needs data.

**Auto-hiding widgets** — set `visible: <condition>`; `Column` collapses the gap automatically because `implicitHeight` returns `0` when `visible: false`.

**Sidebar surface lifetime** — `visible: open || hideTimer.running` keeps surface alive until animation completes. `hideTimer` = 280ms, animation = 260ms.

**Slide-in animation without triggering Behavior** — assign the initial value directly (e.g., `slideX: 360`), then change it in `Component.onCompleted`. The initial assignment predates the `Behavior`, so no animation fires on load. `NotifToast.qml` uses this pattern.

**Process management** — wrap shell commands in `bash -c "..." 2>/dev/null || true` to suppress stderr and prevent silent failures from breaking the parser. Use python3 for writing files (avoids quoting/escaping issues).

---

## Known Pitfalls

**QML / QuickShell:**
- `Layout.fillWidth` only works inside `RowLayout`/`ColumnLayout`, not `Row`/`Column`. Use a spacer `Item` with explicit width.
- `PanelWindow` uses `implicitWidth`/`implicitHeight`, not `width`/`height` — setting `width` emits deprecation warnings.
- `Behavior on transform.xTranslation` is invalid — use an intermediate `property real slideX` with the `Behavior` on that.
- Subdirectory QML files cannot see root-level types without `import "../.." 1.0`. Version suffix is required for `qmldir` registration to work.
- `Singleton {}` root type does NOT expose properties by type name to subdirectory files. Use `pragma Singleton` + `qmldir` registration.
- `PanelWindow` per-monitor: declare `required screen` (not `required property var screen`) to mark inherited property as required without shadowing.
- `QsMenuAnchor.open()` silently fails without `//@ pragma UseQApplication` in `shell.qml`.
- `Text` font properties must be prefixed: `font.letterSpacing`, not bare `letterSpacing`.
- `item.icon` on `SystemTrayItem` returns an `image://` URL, not a raw icon name string.
- SVG files do not load via `file://` in `IconImage` — always use PNG for file-based icon fallbacks.

**QuickShell crash bugs:**
- **StatusNotifierItem IconName segfault** — if any tray application returns a DBus error on `Get(IconName)`, QS crashes with a segfault immediately after logging `WARN quickshell.dbus.properties: QDBusError(..., "error occurred in Get")`. This is a C++ null-check bug in QS; no QML workaround exists. Known offender: `signal-desktop` — fix by going to Signal Settings → Preferences → uncheck "Show tray icon". To identify other offenders: `busctl --user status :<address>` using the address from the log.

**Service-specific:**
- `NotificationService` conflicts with mako/dunst — only one DBus notification daemon can run at a time.
- `AudioService` imports `Quickshell.Services.Pipewire` but never uses it (leftover import — safe to ignore).
- `RecorderService.outputPath` is declared but never set (dead property).
- `BarNetworkPopup` SSID parser splits on `:` — SSIDs containing colons will parse incorrectly.
- `CavaWidget` writes to `/tmp` directly (not `$TMPDIR`) — fails in sandboxed builds.
- `WallpaperService` Hyprland IPC may not be ready on startup; retries once after 500ms delay.
- `BarNetworkPopup` has no timeout for `nmcli connect/rescan` — UI can get stuck in loading state indefinitely.
- `RecorderService` uses SIGINT/SIGUSR1 implicitly — depends on `gpu-screen-recorder` signal handling conventions.
- `BarMediaPopup` progress = 0 when `player.length === 0` or `lengthSupported === false` — no indicator shown.
- `NotifWidget` uses `.values.length` to check count — use `.count` property if available to avoid unnecessary array creation.

# QS_KNOWLEDGE.md — QuickShell Lessons

This file holds the **durable lessons** learned building this config: non-obvious QuickShell
framework behaviors, reusable patterns/conventions, and known pitfalls/crash bugs. It is
deliberately *not* a catalog — the service list, file map, bar/sidebar layout, external
dependencies, and API property tables live in [`CLAUDE.md`](CLAUDE.md), which is the place to
look up (and update) what exists. Keep this file to knowledge that is hard-won and not
derivable from the code or the official docs.

**Where to find QuickShell API details** (this file no longer restates them):
- [QuickShell docs](https://quickshell.outfoxxed.me/docs/) — all built-in types, properties, signals.
- Existing `.qml` files in this repo that already use the API you want.
- [QuickShell source](https://git.outfoxxed.me/outfoxxed/quickshell) — QML type registrations are ground truth for edge cases.
- On upgrade (`qs --version`), read release notes and check for renamed/removed properties, changed signal signatures, and moved enums before assuming existing code still works. If a widget silently breaks after an update, suspect these first.

---

## Key Behavioral Notes (version-agnostic)

Behaviors of the QuickShell framework itself, not specific to this config. Add new ones here as they're discovered.

- **Hot-reload** — QuickShell watches `.qml` files and reloads automatically on save. `//@ pragma UseQApplication` changes and `qmldir` edits require a full restart (`killall qs && qs &`).
- **`pragma Singleton` root must be `QtObject`** — using `Item` as singleton root compiles but silently returns `undefined` for all property accesses.
- **`required screen` vs `required property var screen`** — the former marks the inherited property as required; the latter shadows it with a new property and breaks per-screen assignment.
- **`PanelWindow.implicitWidth`** — setting `width` directly on a `PanelWindow` emits a deprecation warning and may be ignored; always use `implicitWidth`.
- **`Behavior` on initial value** — assigning a property value before its `Behavior` is evaluated (e.g., at declaration time) does not trigger the animation. Use this to set a start position, then animate to the target in `Component.onCompleted`.
- **ObjectModel `.values`** — QuickShell ObjectModels (`Mpris.players`, `Bluetooth.devices`, etc.) expose their contents as a `.values` JS array property. This array is recreated on each access — avoid calling it in tight loops.
- **`Variants` delegate screen binding** — in `Variants { model: Quickshell.screens }`, the delegate must declare `required screen` to receive the screen object. The property name must match the model's element type name exactly.
- **IPC argument types** — all `qs ipc call` arguments arrive as strings in QML. Parse with `parseInt()` / `parseFloat()` / comparison as needed.
- **`SplitParser` and long-running processes** — if the process writes partial lines (no trailing newline), `onRead` won't fire until the delimiter appears. Buffer in a `property string _buf` and handle the final chunk in `onExited` if needed.

---

## Patterns and Conventions

**Singleton pattern** — `pragma Singleton` requires a `QtObject` root. For singletons needing `Timer`/`Process`, declare `property var _impl: Item { ... }` inside the `QtObject`. The inner `Item` hosts all `Timer`/`Process` children. Never use `Item` as singleton root — fails silently. See `SystemInfo.qml:7`, `TodoService.qml:5`.

**Inline component declarations** — private sub-components declared with `component Name: BaseType { ... }` inside the parent file. Cannot be used from other files. Extract to a named `.qml` file only for cross-file sharing.

**Reactive `_revision` counter** — `TodoService._revision` increments on every mutation. Any binding that reads it re-evaluates when the model changes. Use this pattern (not direct `ListModel` bindings) to push mutations across component boundaries. `WallpaperService._wallpapersRev` uses the same pattern for object mutation reactivity.

**Confirmation state machine** — `PowerButtons.qml` uses `property string pendingAction: ""`. First tap: `confirm(cmd)` sets `pendingAction` and shows Confirm/Cancel. Second tap: `execute(cmd)` runs the command and clears `pendingAction`. Reuse for any irreversible action.

**Active-gated polling** — sidebar widgets accept `required property bool active`; set `timer.running: root.active`. `Sidebar.qml` passes `active: root.open`. `SystemInfo` is intentionally NOT gated — the bar always needs data.

**Auto-hiding widgets** — set `visible: <condition>`; a `Column` collapses the gap automatically because `implicitHeight` returns `0` when `visible: false`.

**Sidebar surface lifetime** — `visible: open || hideTimer.running` keeps the Wayland surface alive until the animation completes. `hideTimer` = 280ms, animation = 260ms (20ms margin).

**Slide-in animation without triggering Behavior** — assign the initial value directly (e.g., `slideX: 360`), then change it in `Component.onCompleted`. The initial assignment predates the `Behavior`, so no animation fires on load. `NotifToast.qml` uses this pattern.

**Process management** — wrap shell commands in `bash -c "..." 2>/dev/null || true` to suppress stderr and prevent silent failures from breaking the parser. Use `python3` for writing files (avoids quoting/escaping issues).

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
- `item.icon` on `SystemTrayItem` returns an `image://` URL, not a raw icon name string — string comparisons against plain icon names never match.
- SVG files do not load via `file://` in `IconImage` — always use PNG for file-based icon fallbacks.
- Transparent `PanelWindow`s still capture pointer input over their **entire** rectangle — `color: "transparent"` and `ExclusionMode.Ignore` do NOT make empty areas click-through. A tall/wide transparent window (e.g. a toast stack) will silently swallow clicks to windows beneath it. Fix: set `mask: Region { item: <visibleItem> }` (the `mask` property is on `QsWindow`, inherited by `PanelWindow`; `Region` comes from the `Quickshell` module) so only the painted item is interactive and everything else passes through. Applied in `NotifPopups.qml` (`item: stack`).

**QuickShell crash bugs:**
- **StatusNotifierItem IconName segfault** — if any tray application returns a DBus error on `Get(IconName)`, QS crashes with a segfault immediately after logging `WARN quickshell.dbus.properties: QDBusError(..., "error occurred in Get")`. This is a C++ null-check bug in QS; no QML workaround exists. Known offender: `signal-desktop` — fix by going to Signal Settings → Preferences → uncheck "Show tray icon". To identify other offenders: `busctl --user status :<address>` using the address from the log.

**Service-specific:**
- `NotificationService` conflicts with mako/dunst — only one DBus notification daemon can run at a time.
- `NotificationService.unread` is manually incremented per notification and never auto-decremented on dismiss — call `markRead()` explicitly.
- `BarNetworkPopup` SSID parser splits on `:` — SSIDs containing colons will parse incorrectly.
- `BarNetworkPopup` has no timeout for `nmcli connect/rescan` — UI can get stuck in the loading state indefinitely.
- `CavaWidget` writes its config to `/tmp` directly (not `$TMPDIR`) — fails in sandboxed builds.
- `WallpaperService` Hyprland IPC may not be ready on startup; retries once after a 500ms delay.
- `RecorderService` uses SIGINT (stop) / SIGUSR1 (pause) implicitly — depends on `gpu-screen-recorder` signal-handling conventions.
- `BarMediaPopup` progress = 0 when `player.length === 0` or `lengthSupported === false` — no indicator shown.

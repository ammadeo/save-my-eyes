# Phase 1: Rust core notes

Branch `tauri-migration-rust-core`. `src-tauri` is now the full app core; the frontend talks to it only through the commands and events in `docs/migration/PLAN.md`.

## Modules

| File | Role |
|---|---|
| `src-tauri/src/settings.rs` | `Settings` serde struct (camelCase, `#[serde(default)]` everywhere), `validate()` clamping with `Fix` log, load/save at `app_config_dir()/settings.json` (`settings-dev.json` in debug builds). |
| `src-tauri/src/scheduler.rs` | Break state machine (`idle → before → active → idle`), timer with generation counter + `abort()`, 30 s wall-clock watchdog, `RunEvent::Resumed` check, `break-state`/`break-ended` events. Pure rules (`next_break_index`, `is_long`, `break_length`, `effective_delay`) are unit tested. |
| `src-tauri/src/windows.rs` | `menu`, `before-break`, `break`, `cover-N` builders, plus the destroy hooks that turn a user closing `before-break`/`break` into a skip/end. |
| `src-tauri/src/macos.rs` | AppKit helpers: cover elevation, `before-break` panel styling (rounded corners, all Spaces), show-without-focus, `NSApplication::activate`, Dock hiding. |
| `src-tauri/src/tray.rs` | Template icon, left click opens `menu`, right-click native menu (Open / Start long break now / Quit), localised en/pl. |
| `src-tauri/src/commands.rs` | The 9 commands of the contract. |
| `src-tauri/src/lib.rs` | Plugins, managed state, startup sequence, startup notification text. |

## How to drive it from a webview console

`app.withGlobalTauri` is on, so in any app window's devtools:

```js
const I = window.__TAURI__.core.invoke
await I('get_break_state')
await I('start_break')
await I('end_break')
await I('set_next_break', { opts: { inSecs: 0, forceType: 'long', skipBeforeBreak: true } })
await I('set_settings', { settings: { breaks: { every: 600 } } })
```

Note the argument names: `set_next_break` takes `{ opts }` (optional; omit for `{}`), `set_settings` takes `{ settings }`.

`SME_DEV_EVERY_SECS=8 deno task tauri dev` replaces every non-zero delay with 8 s (legacy `calculateNextBreak` behaviour); `inSecs: 0` still fires at once.

## Verification (2026-11-04, macOS 27.2, one display)

The walk was scripted from inside the real webviews with a temporary, uncommitted Rust helper that ran `window.eval()` with `window.__TAURI__.core.invoke(...)` and read each result back from the URL hash. It used the same IPC path as devtools, because synthetic clicks are blocked by TCC on this Mac. The log showed every transition:

- startup: `phase=Idle index=1`. 8 s later `phase=Before`, and `before-break` appears top-right with rounded corners, without taking focus (`01-before-break-top-right.png`).
- `start_break` from `before-break`: `phase=Active`, `before-break` destroyed, `break` covers the whole screen including the menu bar (`02-break-cover-full-screen.png`).
- `break-ended` listener in `break` fired after `notify_break_ended`.
- `end_break` from `break`: `phase=Idle index=2 long=true`, then `before-break` again 8 s later.
- `close_window` from `before-break`: logged "before-break closed by user in phase Before", index 3, rescheduled.
- `set_settings` from `menu` with `every: 10`: returned `fixes: [{code: "shortEvery", from: 10, to: 60}]`, persisted, `get_settings` returned the clamped values.
- `set_next_break({inSecs:0, forceType:'long', skipBeforeBreak:true})` from `menu`: `index=2 long=true` → straight to `phase=Active length=60`.
- `quit_app` from `before-break`: the process exited.
- `menu` window: native traffic lights, top-right, stays open while `before-break` appears (`03-menu-native-chrome-with-before-break.png`). In the screenshots the placeholder renders the cover page in every window because the test helper rewrote the URL hash.
- No Dock icon: `lsappinfo` reports `type="UIElement"`.
- Tray: `TrayIcon::rect()` reported a 68×66 px status item at x=2062, y=0 (the menu bar). The menu bar itself renders black in `screencapture` output on this Mac (the Claude app was fullscreen), so the icon is not in any screenshot. Right-click menu not exercised (no synthetic input); its "Start long break now" item calls the same `set_next_break` path verified above.

Capability glob: a temporary `cover-7` window could call `window.setFocus()` (needs `core:window:allow-set-focus`); a window labelled `rogue` was refused with "allowed on: [windows: before-break, break, cover-*, menu]". So `"cover-*"` works. App commands are not ACL-gated in Tauri 2 unless an app manifest is declared, so any window can call them; only core/plugin permissions are label-scoped.

## Behaviour details for integration

- Closing `before-break` (via `close_window`, Cmd+W, or anything else) while `phase == before` is a skip. Closing `break` while `phase == active` ends the break. Both call `set_next_break({})` through `scheduler::on_window_destroyed`, like legacy's `closed` handler. App-initiated closes change the phase first, so they never count as user closes.
- `end_break` ignores extra args (`{ finished }` from PLAN.md is accepted and ignored).
- `BreakState.lengthSecs` is computed from the current settings except during `active`, where it is frozen at `start_break`. `scheduledAt` stays set during `before` (it is when that phase began) and is `null` during `active`.
- `set_settings` relabels the tray menu when `lang` changes.
- Autostart: `enable()` runs only in release builds. A debug build skips it unless `SME_DEV_AUTOSTART=1` is set, so a throwaway `target/debug` binary does not become a login item.
- `before-break` sits at the same top-right spot as `menu` and overlaps it if both are open.

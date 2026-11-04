# Electron → Tauri 2 on macOS: capability map

Verified against docs.rs / v2.tauri.app / crates.io on 2026-11-04. Items marked UNVERIFIED are design proposals or behaviour the docs do not state; prototype them first.

## Versions

| Package | Version |
|---|---|
| `tauri` | 2.12.5 |
| `tauri-build` | 2.7.4 |
| `@tauri-apps/api`, `@tauri-apps/cli` | 2.12.4 |
| `tauri-plugin-updater` | 2.14.1 |
| `tauri-plugin-notification` | 2.8.0 |
| `tauri-plugin-opener` | 2.7.2 |
| `tauri-plugin-store` | 2.5.0 |
| `tauri-plugin-autostart` | 2.7.0 |
| `tauri-plugin-process` | 2.4.0 |
| `objc2-app-kit` | 0.3.2 |
| `tauri-apps/tauri-action` | v1 |

## Surprises / blockers

1. **`macOSPrivateApi` is a no-op since 2.12.1.** Transparency and fullscreen are always enabled (wry #1780, "tested on macOS 12.4 and 26"). App Store acceptance UNVERIFIED.
2. **No `forward: true` for ignore-cursor-events.** `set_ignore_cursor_events(bool)` is all-or-nothing; the webview gets no `pointerover` while ignoring, so Electron's renderer-side toggle cannot be ported. Workaround (UNVERIFIED): Rust task polls `app.cursor_position()` ~50 ms and hit-tests against rects the frontend reports. Better: avoid transparent overlays by sizing the BeforeBreak/Menu windows to their card.
3. **No window-level API in Tauri.** `always_on_top` alone does not cover the menu bar, Dock or other apps' fullscreen Spaces. Use `ns_window()` + `objc2-app-kit`: `setLevel(NSScreenSaverWindowLevel)` and `setCollectionBehavior(CanJoinAllSpaces | FullScreenAuxiliary | Stationary)`. Method/constant names verified; behaviour on Tahoe UNVERIFIED, prototype first.
4. **`skip_taskbar` is unsupported on macOS.** Use `ActivationPolicy::Accessory` (+ `LSUIElement` in `src-tauri/Info.plist` to avoid a Dock-icon flash).
5. **`fullscreen(true)` moves the window into a new Space.** Size manually to monitor bounds, or `set_simple_fullscreen`.
6. **Tauri's tokio lacks the `time` feature.** Add `tokio = { version = "1", features = ["time"] }`.
7. **Updater cannot run unsigned** (Tauri minisign key, separate from Apple signing).
8. **Minimum macOS**: config default "10.13", prerequisites page says 10.15; `backgroundThrottling` needs 14.0.

## 1. Primary cover window

`WebviewWindowBuilder`: `decorations(false)`, `resizable(false)`, `always_on_top(true)`, `visible_on_all_workspaces(true)`, `shadow(false)`, `visible(false)`, `content_protected`, `transparent`, `background_throttling`. Builder `position`/`inner_size` take logical units; prefer `set_position`/`set_size` with physical values after build. macOS-only `ns_window() -> *mut c_void` on `WebviewWindow`.

```rust
// Cargo: objc2 = "0.6", objc2-app-kit = { version = "0.3", features = ["NSWindow","NSResponder","NSGraphics"] } (feature set UNVERIFIED)
let w = WebviewWindowBuilder::new(app, "cover-0", WebviewUrl::App("index.html#/blank".into()))
    .decorations(false).resizable(false).always_on_top(true)
    .visible_on_all_workspaces(true).shadow(false).visible(false).build()?;
w.set_position(*m.position())?; w.set_size(*m.size())?;
#[cfg(target_os = "macos")] unsafe {
    use objc2_app_kit::{NSWindow, NSWindowCollectionBehavior as B, NSScreenSaverWindowLevel};
    let ns: &NSWindow = &*w.ns_window()?.cast();
    ns.setLevel(NSScreenSaverWindowLevel);
    ns.setCollectionBehavior(B::CanJoinAllSpaces | B::FullScreenAuxiliary | B::Stationary);
}
w.show()?;
```

Call `ns_window` on the main thread (`setup` already is; otherwise `run_on_main_thread`).

## 2. One cover window per external monitor

`AppHandle::available_monitors()`, `primary_monitor()`. `Monitor` has `name()`, `size()` (physical), `position()` (physical, relative to the virtual screen), `work_area()`, `scale_factor()`. Create windows at runtime from `setup`, an async command, or a spawned task. Label them `cover-0`, `cover-1`… and list them in capabilities (`"cover-*"` glob UNVERIFIED; `"*"` is documented). Monitor hot-plug events: no doc found.

## 3. Click-through transparent overlay

`transparent: true` works on macOS with no extra flag since 2.12.1. Rust: `WebviewWindow::set_ignore_cursor_events(bool)`. JS: `getCurrentWindow().setIgnoreCursorEvents(true)` needs `core:window:allow-set-ignore-cursor-events`. No forward mode (blocker 2).

## 4. Menu-bar-only agent app

`app.handle().set_activation_policy(ActivationPolicy::Accessory)` in `setup`; `set_dock_visibility(bool)` also exists. `src-tauri/Info.plist` next to `tauri.conf.json` is merged automatically; put `LSUIElement = true` there.

## 5. Tray icon and notifications

Cargo feature `tray-icon`. `TrayIconBuilder::new().icon(..).tooltip(..).icon_as_template(true).show_menu_on_left_click(false).on_tray_icon_event(|tray, e| …)`. Events: `TrayIconEvent::Click { button: MouseButton::Left|Right, button_state: MouseButtonState::Up, .. }`. Use a monochrome template icon for the menu bar.

`displayBalloon` replacement: `tauri-plugin-notification`, Rust `app.notification().builder().title(..).body(..).show()`, permission `notification:default`. Works in unsigned dev builds: UNVERIFIED.

## 6. Persisted settings

`tauri-plugin-store` has no schema validation and untyped values. **Recommendation: plain serde.** `#[derive(Serialize, Deserialize)] #[serde(default)] struct Settings` + `validate()`/clamp, stored at `app.path().app_config_dir()?.join("settings.json")`, held in `app.manage(Mutex<Settings>)`, exposed via `get_settings` / `set_settings` commands that broadcast `settings-changed`. No plugin, no JS permissions.

## 7. Start at login

`tauri-plugin-autostart` with `MacosLauncher::LaunchAgent` (writes `~/Library/LaunchAgents/<id>.plist`, no prompt per docs). Rust `app.autolaunch().enable()`; JS `enable()/disable()/isEnabled()`; permission `autostart:default`. The `AppleScript` launcher triggers an Automation prompt. macOS 13+ "Background item added" notification: UNVERIFIED.

## 8. Auto-update and distribution

- `tauri-plugin-updater` + `tauri-plugin-process` (relaunch). Permission `updater:default`.
- Key: `deno task tauri signer generate -w ~/.tauri/save-my-eyes.key`; builds need `TAURI_SIGNING_PRIVATE_KEY` (+ `_PASSWORD`). `.env` files do not work.
- Config: `bundle.createUpdaterArtifacts: true`, `plugins.updater.pubkey` (content, not path), `endpoints: ["https://github.com/ammadeo/save-my-eyes/releases/latest/download/latest.json"]`.
- macOS artifacts: `*.app.tar.gz` + `.sig`. `latest.json`: `{version, notes, pub_date, platforms: {"darwin-aarch64": {url, signature}, "darwin-x86_64": {…}}}`; every platform entry must be complete.
- Apple: distributing outside the App Store needs a paid developer account, a "Developer ID Application" certificate (`bundle.macOS.signingIdentity` / `APPLE_SIGNING_IDENTITY`, CI `APPLE_CERTIFICATE` base64 .p12 + `APPLE_CERTIFICATE_PASSWORD`) and notarization (`APPLE_API_ISSUER/KEY/KEY_PATH` or `APPLE_ID/PASSWORD/TEAM_ID`). Without it, use ad-hoc signing `"signingIdentity": "-"` so Apple Silicon downloads are not reported as damaged. Whether the updater works on ad-hoc builds: UNVERIFIED.
- CI: `tauri-apps/tauri-action@v1` with `tauriScript: "deno task tauri"`, `tagName: app-v__VERSION__`, `uploadUpdaterJson: true`, matrix `macos-latest` × `--target aarch64-apple-darwin` / `--target x86_64-apple-darwin`.

## 9. Timer / scheduler

`tauri::async_runtime::spawn` returns a `JoinHandle` with `abort()`. Pattern: managed state `{ gen: AtomicU64, task: Mutex<Option<JoinHandle>> }`; on schedule bump `gen`, spawn `tokio::time::sleep(secs)` then re-check `gen` before firing; abort the previous handle. Store a wall-clock deadline too and re-check on wake, since monotonic sleep may not advance during system sleep (UNVERIFIED). Set `backgroundThrottling` on windows that keep JS timers (macOS 14+).

## 10. IPC

`#[tauri::command]` + `generate_handler!`; args are serde types, camelCase by default; `async` commands with owned args; can take `AppHandle`, `WebviewWindow`, `State<T>`. Rust → all windows: `use tauri::Emitter; app.emit("evt", payload)`; `emit_to(label, …)`; `emit_filter(…, |t| matches!(t, EventTarget::WebviewWindow{label} if label.starts_with("cover")))`. JS: `listen` from `@tauri-apps/api/event` (global) or `getCurrentWebviewWindow().listen` (per window); always call `unlisten`. `core:event:default` covers listen/unlisten/emit/emit-to.

## 11. Opening external URLs

`tauri-plugin-opener` (already in the scaffold). JS `openUrl(url)`; Rust `app.opener().open_url(url, None::<&str>)`. `opener:default` allows http/https/mailto/tel.

## 12. Bundled mp3

Vite-imported assets under `frontendDist` are served by the app protocol; no asset-protocol config. CSP is only enforced if `app.security.csp` is set (default `null`); if set, include `media-src 'self'`. WKWebView autoplay without a user gesture in a freshly shown window: UNVERIFIED, test early.

## 13. Window control from JS and required permissions

`getCurrentWindow().close()` / `.hide()` from `@tauri-apps/api/window`. `core:window:default` is read-only; grant explicitly: `core:window:allow-close`, `allow-hide`, `allow-show`, `allow-destroy`, `allow-set-focus`, `allow-set-ignore-cursor-events`, `allow-set-always-on-top`, `allow-set-position`, `allow-set-size`, `allow-set-visible-on-all-workspaces`, `allow-set-content-protected`; `core:webview:allow-create-webview-window`; `core:app:allow-set-dock-visibility`; defaults `core:default`, `core:event:default`, `core:tray:default`; plugins `notification:default`, `opener:default`, `autostart:default`, `updater:default`.

Given the recommendation in §6 and §9 (Rust owns windows, scheduler and settings), the frontend needs only: `core:default`, `core:window:allow-close`, `core:window:allow-hide`, `opener:default`, plus app commands.

## 14. Deno as package manager

`create-tauri-app --manager deno` produces a `package.json` (not `deno.json`) with `dev`/`build`/`tauri` scripts; `deno install`, `deno task tauri dev`, `deno task tauri add <plugin>`, `deno add npm:@tauri-apps/plugin-…`. `vite.config.ts` imports `process` from `node:process` for Deno. No open Deno + Vue + Vite issues found.

## 15. Minimum macOS

`bundle.macOS.minimumSystemVersion` default "10.13"; prerequisites say 10.15. Set `"14.0"` if relying on `backgroundThrottling`. Current repo value: 12.0 (raise to 14.0 when that option is used).

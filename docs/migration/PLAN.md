# Tauri migration plan

Status 2026-11-04: scaffold done (Tauri 2.12.5, Vue 3.5, Vite 8, Deno 2.9.8), both sides compile, draft PR #21 open. Nothing from the old app is ported yet.

Companion docs: [renderer-inventory.md](renderer-inventory.md) (what the Vue 2 app does, component by component) and [tauri-macos-capability-map.md](tauri-macos-capability-map.md) (verified Tauri 2 APIs for every Electron feature).

## What the app does (behaviour to preserve)

- Runs at login as a menu-bar-only agent (no Dock icon). Tray icon opens a Menu window: next-break countdown, start long break now, stop protection for 1-3 h, settings, quit.
- Every `breaks.every` seconds (default 20 min) a BeforeBreak toast appears bottom-right on the primary display with Wait / Start / Skip; after it slides out the same window becomes a full-screen Break screen with a countdown, an idea card, a skip/finish button and inline settings. Every `breaks.long.every`-th break (default 3) is a long break (default 5 min) instead of short (default 20 s).
- During a break every external monitor is covered by a Blank window ("wait for break to end" + skip).
- Short breaks auto-close when the clock ends; long breaks wait for the user. Short and long mp3 cues play at start and end, if sounds are on.
- Settings (break lengths and cadence, sounds, language en/pl) are persisted and validated with clamping; a change reschedules the next break and broadcasts the language to all windows.
- Auto-update from GitHub Releases.

## Why it is not trivial

- The Electron main process (`legacy-electron/src/background`, ~600 lines) must be rewritten in Rust: scheduler, tray, window orchestration across monitors, settings store, autostart, updater, IPC.
- The renderer is Vue 2.6 + Vuex + vue-router 3 + Tailwind 1 + animejs + howler + vue-typed-mixins, all EOL, and reaches into Electron's `remote` module from components. It must be rewritten as Vue 3 `<script setup>` + Tailwind 4 (27 components, 4 views, ~2850 lines of SFC).
- Two macOS behaviours have no Tauri 1:1 and are unverified on macOS 26: (a) a cover window above the menu bar, Dock and other apps' fullscreen Spaces needs AppKit window level via `objc2`; (b) click-through transparent windows have no `forward` mode, so the BeforeBreak and Menu overlays must be redesigned as card-sized windows.
- Distribution on macOS needs Apple Developer ID signing + notarization for a clean install, and a Tauri minisign key for the updater. Without the Apple cert, ad-hoc signing is the fallback.

## Architecture decisions (settled)

1. **Rust owns all state and windows.** Scheduler, break index, settings and window lifecycle live in `src-tauri`. The webview never creates windows, never reads files, never schedules. This collapses the Electron IPC surface and keeps capabilities minimal.
2. **Windows** (all frameless, created from Rust at runtime; none in `tauri.conf.json`):
   - `menu`: card-sized (about 500×700 logical), bottom-right of the primary work area, not transparent. Opened from the tray, closed on blur or close button. Replaces the full-height click-through tray window.
   - `before-break`: card-sized, bottom-right, always-on-top, non-focus-stealing (`focused(false)`). On Start it is closed and `break` opens. Replaces the transparent full-screen toast window.
   - `break`: primary monitor bounds, always-on-top, `visible_on_all_workspaces`, AppKit level `NSScreenSaverWindowLevel` + `CanJoinAllSpaces|FullScreenAuxiliary|Stationary`, `content_protected`. Dark background.
   - `cover-N`: one per external monitor, same window treatment, loads the Blank view.
   - Neither transparent nor click-through windows are used anywhere, which removes blocker 2 entirely.
3. **Routing**: single Vite entry, hash router with `/menu`, `/before-break`, `/break`, `/blank`; each window loads `index.html#/<route>`.
4. **Settings**: plain serde struct with `#[serde(default)]` + `validate()` clamping, stored at `app_config_dir()/settings.json`, held in `Mutex<Settings>` managed state. No store plugin.
5. **Frontend bridge**: one module `src/bridge.ts` wrapping `invoke` and `listen`; components never import `@tauri-apps/api` directly. Tests mock this module.
6. **Styling**: Tailwind 4 via `@tailwindcss/vite`, custom palette copied by hex, `@custom-variant hocus`. Drop animejs (CSS keyframes + Date-based countdown), howler (`new Audio`), Vuex (reactive module), vue-typed-mixins (composables), vue-svg-inline-loader (`?raw` glob).
7. **Tests**: Vitest + `@testing-library/vue` for the 5 behaviour specs; Rust unit tests for scheduler and settings validation.
8. **Distribution**: GitHub Actions with `tauri-apps/tauri-action@v1`, `deno task tauri`, aarch64 + x86_64 macOS targets, `latest.json` for the updater. Ad-hoc signing until an Apple Developer ID is configured in secrets. Windows build kept in the matrix.

## IPC contract (shared, settle before parallel work)

Commands (webview → Rust), all async, camelCase on the JS side:

| Command | Args | Returns |
|---|---|---|
| `get_settings` | – | `Settings` |
| `set_settings` | `settings: Settings` | `{ settings: Settings, fixes: FixLog[] }` (clamped values + what changed) |
| `get_break_state` | – | `{ breakIndex, isLong, scheduledAt: string (RFC3339), lengthSecs, phase: 'idle'|'before'|'active' }` |
| `set_next_break` | `{ inSecs?: number, forceType?: 'long'|'short', skipBeforeBreak?: boolean, keepWindows?: boolean }` | `BreakState` |
| `start_break` | – | `BreakState` (closes `before-break`, opens `break` + covers) |
| `end_break` | `{ finished: boolean }` | `BreakState` (closes break + covers, schedules next) |
| `close_window` | – | – (closes the calling window) |
| `quit_app` | – | – |

Events (Rust → every window): `settings-changed` (`Settings`), `break-state` (`BreakState`), `break-ended` (`{}`).

`Settings` shape and defaults are unchanged from `legacy-electron/src/background/db.ts`: `breaks.every` 1200 s [60..3600], `breaks.short.last` 20 s [1..60], `breaks.long.last` 300 s [60..3600], `breaks.long.every` 3 [1..30], `sounds.ui`/`sounds.voice` true, `lang` 'en'|'pl' (default from system locale, `pl*` → pl).

`FixLog` is `{ code: 'shortEvery'|'shortLast'|'longEvery'|'longLast'|'lang'|'sound', from: number, to: number }`; the bilingual message is built in the frontend (`legacy-electron/src/utils/db.ts`).

## Phases and worker split

### Phase 0: macOS spike (1 worker, Rust, blocks phase 1 go/no-go)
Prove on this Mac (macOS 27.2) that a Tauri window with the AppKit level/collection settings covers the menu bar, Dock and another app's fullscreen Space, on primary and an external monitor if available. Also confirm `ActivationPolicy::Accessory` + `LSUIElement` gives no Dock icon and that a tray click opens a window. Deliverable: `src-tauri/src/macos.rs` with the window-elevation helper, a `--spike` dev path, and a written result (works / needs change). This is the only thing that could invalidate the plan.

### Phase 1: parallel implementation (3 workers, disjoint files)
- **Rust core** (`src-tauri/**`): settings, scheduler, break state machine, window manager, tray, autostart, commands and events per the contract, `capabilities/default.json`, `Info.plist`, Rust unit tests. Validation: `cargo build`, `cargo test`, `cargo clippy`.
- **Vue 3 renderer** (`src/**`, `index.html`, `vite.config.ts`, `package.json` deps): bridge module, i18n composable, countdown composable, 27 components, 4 views, assets, Tailwind 4 theme and custom CSS, 5 Vitest specs. Validation: `deno task build`, `deno task test`, `vue-tsc`. Builds against a mocked bridge until the Rust side lands.
- **CI/release** (`.github/workflows/**`, `README.md`, `tauri.conf.json` bundle/updater sections only): tauri-action workflow for macOS + Windows, updater config with a placeholder pubkey and documented secret names, README update (macOS download, Deno dev commands). Validation: `actionlint` or a dry-run of the workflow YAML.

### Phase 2: integration (lead)
Wire both sides in `tauri dev`, walk the full flow (tray → menu → settings → before-break → break → covers → end → reschedule, long break, stop protection, quit), fix contract drift, delete `legacy-electron/`, mark the PR ready.

### Out of scope for this PR
App Store packaging; Windows-specific polish beyond "it builds"; new features.

## Open decisions for the owner

1. Apple Developer ID signing and notarization: do you have a paid Apple developer account to add `APPLE_CERTIFICATE` and notarization secrets, or ship ad-hoc signed for now?
2. Generate the Tauri updater key now (`deno task tauri signer generate`) and store the private key as a GitHub secret?
3. Minimum macOS: 14.0 (needed for `backgroundThrottling` control) or lower?

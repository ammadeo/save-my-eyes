# Tauri migration plan

Status 2026-11-04 (evening): Phase 0 passed, Phase 1 landed (PR #22 Rust core, PR #23 renderer), Phase 2 integration branch runs the full break loop end to end on macOS 27.2 (`docs/migration/phase2-integration/`). `legacy-electron/` removed; the Vue 2 sources live in git history before commit 55f661f. Remaining unverified: real tray clicks and the startup notification (no synthetic input on the dev Mac), multi-monitor covers (one display), long-break and settings panes in real windows, autostart (release builds only).

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
   - `menu`: a normal macOS utility-style window (about 420×560 logical) opened from the tray, positioned under the tray icon / top-right of the primary work area. Native decorations: `decorations(true)`, `title_bar_style(TitleBarStyle::Overlay)`, `hidden_title(true)`, `resizable(false)`, `minimizable(false)`, so the real red/yellow traffic lights are used and the content extends under a transparent title bar. Closes with the native close button, Cmd+W and Escape, and on blur. Replaces the full-height click-through tray window and the custom CardCloseable close buttons. Settings, stop-protection and the menu list live in this one window.
   - `before-break`: a small notification-style panel (about 360×140 logical) top-right of the primary work area, `decorations(false)`, rounded corners + system shadow, always-on-top, non-focus-stealing (`focused(false)`), styled like a macOS notification banner. On Start it is closed and `break` opens. Replaces the transparent full-screen toast window.
   - `break`: primary monitor bounds, always-on-top, `visible_on_all_workspaces`, AppKit level `NSScreenSaverWindowLevel` + `CanJoinAllSpaces|FullScreenAuxiliary|Stationary`, `content_protected`. Dark background.
   - `cover-N`: one per external monitor, same window treatment, loads the Blank view.
   - Neither transparent nor click-through windows are used anywhere, which removes blocker 2 entirely.
3. **Routing**: single Vite entry, hash router with `/menu`, `/before-break`, `/break`, `/blank`; each window loads `index.html#/<route>`.
4. **Settings**: plain serde struct with `#[serde(default)]` + `validate()` clamping, stored at `app_config_dir()/settings.json`, held in `Mutex<Settings>` managed state. No store plugin.
5. **Frontend bridge**: one module `src/bridge.ts` wrapping `invoke` and `listen`; components never import `@tauri-apps/api` directly. Tests mock this module.
6. **Styling**: Tailwind 4 via `@tailwindcss/vite`, custom palette copied by hex, `@custom-variant hocus`. Drop animejs (CSS keyframes + Date-based countdown), howler (`new Audio`), Vuex (reactive module), vue-typed-mixins (composables), vue-svg-inline-loader (`?raw` glob).
7. **Native macOS feel (owner request).** Everything except the break cover should feel like a macOS app, not a web page:
   - Window chrome comes from macOS (traffic lights, title-bar overlay); no custom close/minimize buttons anywhere outside the cover.
   - System font stack (`-apple-system, BlinkMacSystemFont, "SF Pro", system-ui`) for the menu, settings and before-break UI; the Comfortaa/Source Sans brand fonts are kept only on the break cover.
   - Follow the system appearance: light/dark via `prefers-color-scheme`, using macOS-like neutral surfaces (translucent sidebar grey / window background), 13px body text, native-looking switches (toggle), sliders and push buttons (styled to resemble AppKit controls; prefer `<input type=range>` and `<input type=checkbox role=switch>` with `appearance: auto` where the WebKit rendering already looks native). Respect `prefers-reduced-motion`.
   - Keyboard: Cmd+W and Escape close the menu window; Cmd+Q quits (native app menu kept with the default Tauri menu so the app has a proper application menu).
   - The break cover (`break`, `cover-N`) keeps the existing branded full-screen design, dark #121959 background, large countdown, idea card.
8. **Tests**: Vitest + `@testing-library/vue` for the 5 behaviour specs; Rust unit tests for scheduler and settings validation.
9. **Distribution**: deferred. Local `deno task tauri dev` and `deno task tauri build` (ad-hoc signed) only until signing is in scope.

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
**Result 2026-11-04: PASSED on macOS 27.2.** `NSScreenSaverWindowLevel` + `CanJoinAllSpaces|FullScreenAuxiliary|Stationary` covers the menu bar, Dock and another app's native fullscreen Space (evidence: `spike/02-cover-primary.png`, `spike/04-cover-over-fullscreen-space.png`; the dialog in them is an unrelated macOS automation prompt). `ActivationPolicy::Accessory` + `LSUIElement` hides the Dock icon; the tray icon shows; the menu window with `TitleBarStyle::Overlay` + `hidden_title` renders native traffic lights and closes via the red button and Cmd+W. Multi-monitor path compiles but is unverified (one display). Phase 1 notes from the spike: keep `elevate_cover_window` on the main thread; do not set `content_protected` on covers (hides them from screenshots); if the menu opens unfocused call `NSApplication::activate`; add a right-click tray menu with Quit; use a monochrome template tray icon; delete `spike.rs` and its Cargo lines; narrow capabilities from `"*"` to real labels.

Prove on this Mac (macOS 27.2) that a Tauri window with the AppKit level/collection settings covers the menu bar, Dock and another app's fullscreen Space, on primary and an external monitor if available. Also confirm `ActivationPolicy::Accessory` + `LSUIElement` gives no Dock icon and that a tray click opens a window. Deliverable: `src-tauri/src/macos.rs` with the window-elevation helper, a `--spike` dev path, and a written result (works / needs change). This is the only thing that could invalidate the plan.

### Phase 1: parallel implementation (3 workers, disjoint files)
- **Rust core** (`src-tauri/**`): settings, scheduler, break state machine, window manager, tray, autostart, commands and events per the contract, `capabilities/default.json`, `Info.plist`, Rust unit tests. Validation: `cargo build`, `cargo test`, `cargo clippy`.
- **Vue 3 renderer** (`src/**`, `index.html`, `vite.config.ts`, `package.json` deps): bridge module, i18n composable, countdown composable, 27 components, 4 views, assets, Tailwind 4 theme and custom CSS, 5 Vitest specs. Validation: `deno task build`, `deno task test`, `vue-tsc`. Builds against a mocked bridge until the Rust side lands.
- **CI/release**: deferred (owner decision, see bottom).

### Phase 2: integration (lead)
**Result:** `tauri-migration-integration` merges both Phase 1 branches; fixes: `core:window:allow-start-dragging`, the banner closes an open `menu` window, `.claude/worktrees/` ignored. `SME_DEV_EVERY_SECS=8 deno task tauri dev` ran idle → banner → auto-start → break (sound at start and end) → idle → banner twice with no input.

Wire both sides in `tauri dev`, walk the full flow (tray → menu → settings → before-break → break → covers → end → reschedule, long break, stop protection, quit), fix contract drift, delete `legacy-electron/`, mark the PR ready.

### Out of scope for this PR
App Store packaging; Windows-specific polish beyond "it builds"; new features.

## Decisions taken by the owner (2026-11-04)

- **Scope for now: run the app locally.** Apple Developer ID signing, notarization and App Store topics are out of scope entirely. The CI/release slice is deferred; no updater key is generated. Phase 1 therefore has two parallel workers (Rust core, Vue renderer) and the release workflow waits.
- **Autonomy:** if Phase 0 passes, Phases 1 and 2 proceed without further approval, as stacked PRs targeting `tauri-migration` (one per slice). Stop only where a behaviour clearly has no clean migration path.
- Minimum macOS: keep 12.0 for now; revisit if `backgroundThrottling` (14.0+) is needed.

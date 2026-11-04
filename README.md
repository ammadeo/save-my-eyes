<h1> Save My Eyes </h1>
<p>
<h3>App that helps you protect your eyes while working long on a computer</h3>
<img align="center" src="https://i.ibb.co/94DJ8DP/rsz-5f7c7771956a8.jpg" alt="save my eyes screenshot">
<p align="center">Save My Eyes long break screenshot</p>
<h3>What You can expect</h3>
<ul>
  <li>App will run on a computer startup</li> 
  <li>It's easy to customize Your break time</li> 
  <li>It'll prevent You from using Your computer, when You need a break (Don't worry You can always skip it with one click :wink:)</li> 
  <li>You can accesses all options from tray menu</li>
  <li>It works on multiple monitors setup</li>
  <li>It's free! <a href="https://www.buymeacoffee.com/ammadeo">You can buy me a coffee here :coffee:</a></li> 
</ul>
<br/>
<p><a href="https://github.com/ammadeo/save-my-eyes/releases/download/v0.3.0/Save.My.Eyes_0.3.0_aarch64.dmg">Download for macOS (v0.3.0, Apple Silicon, macOS 12+)</a>. The build is not notarized yet: on first launch right-click the app and choose Open. The last Windows build is the <a href="https://github.com/ammadeo/save-my-eyes/releases/download/v0.2.2/save-my-eyes-Setup-0.2.2.exe">Electron v0.2.2 installer</a>.</p>
<br/>
</p>

## Development (Tauri 2 + Vue 3 + Deno)

Prerequisites: [Deno](https://deno.com) 2.9 (pinned in `.tool-versions`), a Rust toolchain via [rustup](https://rustup.rs), and on macOS the Xcode Command Line Tools (full Xcode 26+ to compile the Liquid Glass app icon; without it the build falls back to `icon.icns`).

```bash
deno install
```

```bash
deno task tauri dev
```

```bash
deno task tauri build
```

- `deno task build` builds only the frontend; `deno task test` runs the Vitest unit tests; `cargo test` inside `src-tauri` runs the Rust tests.
- `SME_DEV_EVERY_SECS=8 deno task tauri dev` makes the first break fire after 8 seconds instead of the configured interval; `SME_DEV_OPEN_MENU=1` opens the menu window at startup.
- Settings are stored in the app config directory as `settings.json` (`settings-dev.json` for debug builds).
- The migration notes live in [`docs/migration/`](docs/migration/PLAN.md).
- Design: [`PRODUCT.md`](PRODUCT.md) records what the app is for, [`DESIGN.md`](DESIGN.md) the visual system (sage on native Liquid Glass, system font, follows the macOS appearance). The windows are transparent and painted by the native material from `src-tauri/src/windows.rs`; the CSS tokens live in `src/css/glass.css`.

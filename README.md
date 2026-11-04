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
<p><a href="https://github.com/ammadeo/save-my-eyes/releases/download/v0.2.2/save-my-eyes-Setup-0.2.2.exe">Download for Windows (v0.2.2, Electron)</a>. A native macOS build on Tauri is in progress on the <code>tauri-migration</code> branch.</p>
<br/>
</p>

## Development (Tauri 2 + Vue 3 + Deno)

Prerequisites: [Deno](https://deno.com) 2.9 (pinned in `.tool-versions`), a Rust toolchain via [rustup](https://rustup.rs), and on macOS the Xcode Command Line Tools.

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
- `SME_DEV_EVERY_SECS=8 deno task tauri dev` makes the first break fire after 8 seconds instead of the configured interval.
- Settings are stored in the app config directory as `settings.json` (`settings-dev.json` for debug builds).
- The migration notes live in [`docs/migration/`](docs/migration/PLAN.md).

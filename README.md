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
  <li>If a break screen ever goes wrong (nothing visible, a button missing, the app frozen), <kbd>Control</kbd>+<kbd>Option</kbd>+<kbd>Command</kbd>+<kbd>Escape</kbd> (⌃⌥⌘⎋) skips the break from anywhere</li>
  <li>You can accesses all options from tray menu</li>
  <li>It works on multiple monitors setup</li>
  <li>It holds a break while your calendar shows a meeting, or while an app is using your camera or microphone</li>
  <li>It's free! <a href="https://www.buymeacoffee.com/ammadeo">You can buy me a coffee here :coffee:</a></li>
</ul>
<br/>
<p>Save My Eyes is a native macOS menu-bar app (Swift, SwiftUI and AppKit; macOS 14 or later). The last Windows build is <a href="https://github.com/ammadeo/save-my-eyes/releases/download/v0.2.2/save-my-eyes-Setup-0.2.2.exe">v0.2.2 (Electron)</a>.</p>
</p>

## Development (Swift, Xcode 26+)

Prerequisites: Xcode 26 or later and [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`). The Xcode project is generated from `SaveMyEyes/project.yml` and is not committed.

```bash
make project
```

```bash
make build
```

```bash
make test
```

```bash
SME_DEV_EVERY_SECS=8 SME_DEV_OPEN_MENU=1 make run
```

- `make project` writes `SaveMyEyes/SaveMyEyes.xcodeproj`; open it in Xcode to work there. Any `.swift` file added under `SaveMyEyes/Sources` or `SaveMyEyes/Tests` is picked up on the next `make project` (every `make` target runs it).
- `make run` starts a debug build. `SME_DEV_EVERY_SECS=8` makes the first break fire after 8 seconds instead of the configured interval; `SME_DEV_OPEN_MENU=1` (or `settings` / `stop-protection`) opens the menu at startup; `SME_DEV_AUTOSTART=1` lets a debug build register itself as a login item (release builds always do).
- `make release` builds `Save My Eyes.app` for distribution (ad-hoc signed; Developer ID signing and notarization need an Apple Developer account).
- Settings are stored as JSON in `~/Library/Application Support/com.ammadeo.savemyeyes/settings.json` (`settings-dev.json` for debug builds), the same file the earlier Tauri build used.
- Layout: `SaveMyEyes/Sources/Core` (settings, scheduler, calendar, call detection, model), `Sources/Windows` (status item popover, before-break panel, break covers, glass material), `Sources/Views` (SwiftUI), `Sources/App` (entry, login item, notification), `Tests` (XCTest).
- Design: [`PRODUCT.md`](PRODUCT.md) records what the app is for, [`DESIGN.md`](DESIGN.md) the visual system (sage on native Liquid Glass, system font, follows the macOS appearance). The history of the Electron → Tauri → Swift rewrites lives in [`docs/migration/`](docs/migration/PLAN.md).

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
  <li>It pauses breaks during calendar events, and while an app is using your camera or microphone</li>
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
- `make run` starts a debug build. `SME_DEV_EVERY_SECS=8` makes the first break fire after 8 seconds instead of the configured interval; `SME_DEV_OPEN_MENU=1` (or `settings` / `stop-protection`) opens the menu at startup; `SME_DEV_CALL=20` makes the microphone read as in use for the first 20 seconds, to see the paused state (pause bars in the menu-bar icon, "Breaks are paused" in the menu) without starting a call, as long as "Pause breaks while camera or microphone is on" is on; `SME_DEV_AUTOSTART=1` lets a debug build register itself as a login item (release builds always do).
- `make release` builds `Save My Eyes.app`. `make dist` builds the universal DMG in `dist/`, and `make install` also puts that build in `/Applications` and starts it.
- `make dist` signs and notarizes the DMG by itself when a Developer ID certificate is on the Mac; otherwise it stays ad-hoc signed and downloads show "Apple could not verify" (see [Signing releases](#signing-releases)).
- Settings are stored as JSON in `~/Library/Application Support/com.ammadeo.savemyeyes/settings.json` (`settings-dev.json` for debug builds), the same file the earlier Tauri build used.
- Layout: `SaveMyEyes/Sources/Core` (settings, scheduler, calendar, call detection, model), `Sources/Windows` (status item popover, before-break panel, break covers, glass material), `Sources/Views` (SwiftUI), `Sources/App` (entry, login item, notification), `Tests` (XCTest).
- Design: [`PRODUCT.md`](PRODUCT.md) records what the app is for, [`DESIGN.md`](DESIGN.md) the visual system (sage on native Liquid Glass, system font, follows the macOS appearance). The history of the Electron → Tauri → Swift rewrites lives in [`docs/migration/`](docs/migration/PLAN.md).

### Signing releases

Only a paid [Apple Developer Program](https://developer.apple.com/programs/) membership can remove the "Apple could not verify" warning from downloaded builds. A free Apple ID can't create the certificate. Setup is once per Mac:

1. In Xcode, open Settings › Accounts, add the Apple ID, then Manage Certificates › + › Developer ID Application.
2. Create an app-specific password at [account.apple.com](https://account.apple.com), then save the notarization login in the keychain:

```bash
xcrun notarytool store-credentials save-my-eyes --apple-id <apple-id> --team-id <team-id>
```

From then on every `make dist` signs with the hardened runtime, notarizes, and staples the ticket to the DMG.

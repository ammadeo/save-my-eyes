# Product

<!-- impeccable:product-schema 1 -->

## Platform

macOS (native)

(Swift, SwiftUI and AppKit. A menu-bar agent with a status-item popover and native panels and windows; no web view. Rewritten from Tauri 2 + Vue 3 on 2026-11-04.)

## Users

People who work long hours at a Mac and want to protect their eyes without thinking about it. They install the app once, let it run at login, and meet it only when a break comes up. (Inferred from the README and the migration plan; not interviewed.)

## Product Purpose

Save My Eyes schedules eye breaks: every 20 minutes (configurable) it asks for a short break (20 s by default), and every third break is a long one (5 min by default). During a break it covers every display so the computer cannot be used, while always leaving a one-click way out. Success is a break that actually gets taken, with the least friction and the least noise.

## Positioning

A menu-bar agent that enforces breaks gently: the break is a full-screen cover you can always skip, not a nag. It is free and open source (GPL-3.0), bilingual (English, Polish), and native on macOS (Swift).

## Operating Context

- Runs as a menu-bar-only agent (no Dock icon), started at login.
- Four surfaces, all created from `WindowManager` at runtime: the menu (an `NSPopover` under the status item with countdown, long-break shortcut, stop protection, settings, quit), the before-break card (a non-activating panel top-right of the primary display: Wait / Start / Skip, auto-starts in 5 s), the break cover (full-screen window on the primary display: countdown, idea card, skip/finish, inline settings and stop protection), and a blank cover on every other display.
- Short breaks auto-close when the clock ends; long breaks wait for the user. Short and long sound cues play at start and end when sounds are on.
- Settings (cadence, lengths, sounds, language, meeting hold and its pause after a call) persist in a JSON file and are clamped by `Settings.validate()`.

## Capabilities and Constraints

- Swift 5 language mode, SwiftUI views hosted in AppKit windows, xcodegen project (`SaveMyEyes/project.yml`), XCTest unit tests (`make test`).
- macOS 14 is the minimum, the development Mac runs macOS 27.2. The native window materials (Liquid Glass on macOS 26+, NSVisualEffectView materials before) are painted by `Sources/Windows/GlassBacking.swift`; SwiftUI views paint no background.
- `AppModel` is the one object views talk to; `WindowCoordinating` and `CalendarServicing` (`Sources/Core/Contracts.swift`) are the fixed seams between core, windows and calendar.
- Unit tests in `SaveMyEyes/Tests` must keep passing; they cover settings clamping and persistence, the break rules and scheduler, calendar rules and the settings form.
- Terminology: "short break", "long break", "stop protection" (pause for 1–3 h), "turn off protection" (quit for this session).

## Brand Commitments

- Name: Save My Eyes. Author: Ammadeo. Illustrations by Katerina Limpitsouni (unDraw), credited in settings.
- Binding visual constraint from the owner (2026-11-04): Liquid Glass window material, sage accent, very light, minimalist, zen; the window follows the user's macOS light/dark setting; system font only, no custom typeface.

## Evidence on Hand

- Six unDraw illustrations for break ideas in `src/assets/images/`, app icon in `src/assets/app-icon.png`, ten inline SVG icons in `src/assets/icons/`, two sound cues in `src/assets/music/`.
- Screenshots of the previous (navy "brand") look in `docs/migration/`.
- No testimonials, metrics or press; do not invent any.

## Product Principles

- Only what has to be there is there: a break screen is a pause, not a dashboard.
- Never trap: every cover offers a one-click exit.
- Follow the Mac: system appearance, system font, system materials and controls where a native one exists.
- Calm by default: colour only on the one action that matters and on progress.
- Bilingual parity: every string exists in English and Polish.

## Accessibility & Inclusion

- Honour Reduce Motion (already respected in transitions) and Reduce Transparency (the native material handles it; CSS surfaces must stay legible on an opaque fallback).
- Keep all behaviour reachable by keyboard (Escape closes the menu; focus rings visible).

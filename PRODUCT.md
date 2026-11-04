# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

(The web UI runs inside WKWebView windows of a Tauri 2 macOS menu-bar app. There is no browser build; every surface is a native window.)

## Users

People who work long hours at a Mac and want to protect their eyes without thinking about it. They install the app once, let it run at login, and meet it only when a break comes up. (Inferred from the README and the migration plan; not interviewed.)

## Product Purpose

Save My Eyes schedules eye breaks: every 20 minutes (configurable) it asks for a short break (20 s by default), and every third break is a long one (5 min by default). During a break it covers every display so the computer cannot be used, while always leaving a one-click way out. Success is a break that actually gets taken, with the least friction and the least noise.

## Positioning

A menu-bar agent that enforces breaks gently: the break is a full-screen cover you can always skip, not a nag. It is free and open source (GPL-3.0), bilingual (English, Polish), and native on macOS (Tauri + Rust core).

## Operating Context

- Runs as a menu-bar-only agent (no Dock icon), started at login.
- Four window kinds, all created from Rust at runtime: `menu` (tray popover with countdown, long-break shortcut, stop protection, settings, quit), `before-break` (a small card top-right of the primary display: Wait / Start / Skip, auto-starts in 5 s), `break` (full-screen cover on the primary display: countdown, idea card, skip/finish, inline settings and stop protection), and `cover-N` (blank cover on every other display).
- Short breaks auto-close when the clock ends; long breaks wait for the user. Short and long sound cues play at start and end when sounds are on.
- Settings (cadence, lengths, sounds, language) persist in a JSON file and are clamped by the Rust side.

## Capabilities and Constraints

- Tauri 2.12 + Vue 3.5 + Tailwind 4 + Vite 8 frontend, Deno task runner, Vitest specs for behaviour; Rust core with `cargo test`.
- macOS 12+ is the bundle minimum, the development Mac runs macOS 27.2. The native window materials (Liquid Glass on macOS 26+, NSVisualEffectView materials before) are applied from Rust.
- Window labels, IPC commands and events are a fixed contract (`src/bridge.ts`, `src-tauri/src/commands.rs`).
- Behaviour specs in `src/**/*.spec.ts` must keep passing; they test copy and roles, not styling.
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

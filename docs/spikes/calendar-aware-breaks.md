# Spike: don't show breaks during meetings (Google Calendar)

Status 2026-11-04: research only, no code. Goal: when a break is due while the user is in a meeting, hold it until the meeting ends.

## Where it plugs in

All break timing lives in `src-tauri/src/scheduler.rs`. Every path that shows a break goes through `fire()` (the timer task, the `check_deadline` sleep/wake watchdog, and `set_next_break` with `inSecs: 0`). So the change is one gate in `fire()`:

```
fire(generation):
  if phase == Idle && busy.covers(now) && !user_forced:
      reschedule to busy.end_of_block(now) + grace   // keep break_index, don't advance
      return
  ...existing behaviour
```

- `busy` is an in-memory list of `(start, end)` intervals, refreshed in the background every 5-10 min and on wake. `fire()` only reads the cache, so it stays synchronous, never waits on the network and keeps working offline.
- `end_of_block` merges back-to-back and overlapping meetings, so 3 meetings in a row give one postponement instead of three.
- `user_forced`: "Start long break now" from the menu (`inSecs: 0`) must still work during a meeting. That needs a new flag on `NextBreakOptions`, or a rule that `inSecs == 0` skips the gate.
- Fail open: no calendar, revoked token or a stale cache older than about 1 h means breaks behave as they do today.
- Also needed: one settings toggle (`calendar.enabled`) plus "connect/disconnect" and status rows in `MenuSettings.vue`, and a menu countdown that says "after your meeting" when a break was held.

The scheduler part is about **0.5-1 day** whichever data source is used. The data source is where the options differ.

## Options for the data source

The app is macOS-only (`bundle.targets: app, dmg`, AppKit code in `macos.rs`), which makes the first option possible.

### A. macOS Calendar via EventKit (recommended first step)

Read events from the system calendar store. If the user has added their Google account in System Settings → Internet Accounts, Google calendars are already in that store. The same code also covers iCloud, Exchange/Outlook and CalDAV.

- Crate: `objc2-event-kit` (from the same objc2 family already used for AppKit). Calls: `EKEventStore`, `requestFullAccessToEventsWithCompletion` (macOS 14+) or `requestAccessToEntityType` (12-13), then `predicateForEventsWithStartDate:endDate:calendars:` and `eventsMatchingPredicate:` for the next ~12 h.
- Filter out all-day events, events marked "free" (`availability`) and events the user declined (`participationStatus` of self). Optionally let the user pick calendars.
- `Info.plist`: `NSCalendarsFullAccessUsageDescription` and `NSCalendarsUsageDescription`. Hardened runtime/notarization later needs the `com.apple.security.personal-information.calendars` entitlement.
- No server, no OAuth, no Google app verification, no secrets, no new network code.
- Downsides: the user must have Google added to macOS. macOS syncs Google every few minutes, so an invite created a moment ago may be missed. TCC permission for an ad-hoc signed dev build may be asked for again after each rebuild.
- Effort: **~1.5-2.5 days** including the scheduler gate and settings UI.

### B. Google Calendar API directly

Use this for users who don't want Google in macOS Internet Accounts, or if the app ever ships outside macOS.

- **Auth:** OAuth 2.0 "installed app" flow: PKCE, system browser, loopback redirect to `http://127.0.0.1:<random port>`. Google treats a desktop client secret as not confidential, so shipping it in the binary is allowed. Needs a Google Cloud project with an OAuth client of type "Desktop".
- **Scope:** request the narrowest scope that works. Options are `calendar.freebusy` (busy blocks only, no titles, `freeBusy.query`) and `calendar.events.freebusy` / `calendar.readonly`. Free/busy is enough for this feature and is the easiest to justify in review. It already excludes events marked "free" and events the user declined.
- **Google verification:** calendar scopes are *sensitive* (not *restricted*), so no paid CASA security assessment is required. Until the app is verified, though, users see an "unverified app" screen and the app is capped at 100 users. Verification needs a privacy policy URL, a homepage, a verified domain and a demo video. Plan for **days to a few weeks** of calendar time, not developer time.
- **Rust side:** new deps `oauth2` (or a hand-rolled PKCE exchange), `reqwest` with rustls, `keyring` (refresh token in macOS Keychain, never in `settings.json`), and a tiny one-shot loopback HTTP listener (`tiny_http` or tokio TCP). Opening the browser already works through `tauri-plugin-opener`.
- **Edge cases:** refresh-token revocation (`invalid_grant` → mark disconnected and fail open), multiple Google accounts, choosing which calendars to query (`calendarList.list` needs `calendar.calendarlist.readonly` or `calendar.readonly`), time zones (use UTC on the wire).
- Effort: **~4-6 days** of developer time plus the verification process. Push updates are not needed: polling free/busy every 5-10 min is cheap and well inside quota.

### C. Complement: detect "in a call" from camera/microphone

Calendars miss ad-hoc huddles and calls that run over time. macOS can report whether any process is using the mic (CoreAudio `kAudioDevicePropertyDeviceIsRunningSomewhere` on the default input device) or the camera (CoreMediaIO `kCMIODevicePropertyDeviceIsRunningSomewhere`). This needs no permission prompt and no account. It costs about 1 day and gives the same "hold the break" result. It can't look ahead, so it can only postpone, never plan. It is worth considering as the first version on its own, since it covers the "don't interrupt my call" pain with zero setup for the user.

## Product decisions to make

1. Hold vs skip: when a meeting ends, show the held break right away (with a small grace period, e.g. 1-2 min) or restart the full interval? Recommendation: show it soon after, since the user has been staring at a screen through the meeting.
2. Long meetings: should a 2 h meeting count as rest? Probably not. Keep the break index so the next break stays long if it was going to be long.
3. Before-break toast showing when a meeting starts: dismiss it automatically, or leave it?
4. Which events count: only events with attendees / a video link, or anything marked busy? Free/busy can't tell these apart; EventKit and `events.list` can.

## Recommendation

1. Build the scheduler gate behind a `BusySource` trait (`fn busy_until(now) -> Option<DateTime>`) with a cached-interval implementation and unit tests. This is shared by all options.
2. Ship **A (EventKit)** as the first source, optionally together with **C (mic/camera)**. That covers Google users who have Google in macOS, plus every other calendar provider, with no backend and no Google review.
3. Build **B (Google OAuth)** only if users ask for it, and start the Google verification paperwork in parallel, because that is the long pole.

//! Break state machine and timer: idle --(timer)--> before --(start)--> active --(end)--> idle.
//!
//! Semantics follow `legacy-electron/src/background/breaker.ts`. A break that comes due
//! during a calendar meeting is held until the meeting ends (`calendar::held_until`). State lives in one
//! `Mutex<Scheduler>`; window work is queued on the main thread *after* the lock is
//! released (`run_on_main_thread` runs inline on the main thread, so holding the lock
//! across it could deadlock through window event handlers).

use std::sync::{Mutex, MutexGuard};
use std::time::Duration;

use chrono::{DateTime, SecondsFormat, Utc};
use serde::{Deserialize, Serialize};
use tauri::async_runtime::JoinHandle;
use tauri::{AppHandle, Emitter, Manager};

use crate::settings::{Breaks, Settings};
use crate::windows::{self, on_main};

pub const EVT_BREAK_STATE: &str = "break-state";
pub const EVT_BREAK_ENDED: &str = "break-ended";
/// Dev aid: replaces every non-zero break delay with this many seconds.
pub const DEV_EVERY_ENV: &str = "SME_DEV_EVERY_SECS";
/// How often the wall-clock deadline is re-checked (monotonic timers stop during sleep).
pub const WATCHDOG_EVERY: Duration = Duration::from_secs(30);

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Serialize)]
#[serde(rename_all = "lowercase")]
pub enum Phase {
    #[default]
    Idle,
    Before,
    Active,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum ForceType {
    Long,
    Short,
}

#[derive(Debug, Clone, Default, Deserialize)]
#[serde(default, rename_all = "camelCase")]
pub struct NextBreakOptions {
    pub in_secs: Option<u32>,
    pub force_type: Option<ForceType>,
    pub skip_before_break: bool,
    pub keep_windows: bool,
}

/// Wire shape of the `break-state` event and of every break command's result.
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct BreakState {
    pub break_index: u32,
    pub is_long: bool,
    pub phase: Phase,
    pub scheduled_at: Option<String>,
    pub length_secs: u32,
    pub started_at: Option<String>,
    /// The break came due during a meeting and now waits for it to end.
    pub held_for_meeting: bool,
}

#[derive(Default)]
pub struct Scheduler {
    break_index: u32,
    phase: Phase,
    scheduled_at: Option<DateTime<Utc>>,
    started_at: Option<DateTime<Utc>>,
    /// Frozen at `start_break` so a settings change does not alter a running break.
    active_length: u32,
    skip_before_break: bool,
    held_for_meeting: bool,
    /// Bumped on every (re)schedule and on break start; a timer only fires if it still matches.
    generation: u64,
    task: Option<JoinHandle<()>>,
}

// ---- pure rules (unit tested) ----

/// `breakIndex` after `set_next_break`, exactly like legacy `NewBreakIndex`.
pub fn next_break_index(old: u32, force: Option<ForceType>, long_every: u32) -> u32 {
    match force {
        Some(ForceType::Long) => long_every,
        Some(ForceType::Short) => 1,
        None => old.saturating_add(1),
    }
}

pub fn is_long(break_index: u32, long_every: u32) -> bool {
    break_index.is_multiple_of(long_every.max(1))
}

pub fn break_length(is_long: bool, breaks: &Breaks) -> u32 {
    if is_long {
        breaks.long.last
    } else {
        breaks.short.last
    }
}

/// Seconds until the next break fires. A dev override replaces any non-zero delay
/// (legacy `calculateNextBreak`); zero always means "now".
pub fn effective_delay(in_secs: Option<u32>, every: u32, dev_override: Option<u32>) -> u32 {
    match in_secs.unwrap_or(every) {
        0 => 0,
        d => dev_override.unwrap_or(d),
    }
}

fn dev_override() -> Option<u32> {
    std::env::var(DEV_EVERY_ENV).ok()?.trim().parse().ok()
}

fn rfc3339(t: DateTime<Utc>) -> String {
    t.to_rfc3339_opts(SecondsFormat::Millis, true)
}

impl Scheduler {
    pub fn snapshot(&self, s: &Settings) -> BreakState {
        let long = is_long(self.break_index, s.breaks.long.every);
        let length_secs = match self.phase {
            Phase::Active => self.active_length,
            _ => break_length(long, &s.breaks),
        };
        BreakState {
            break_index: self.break_index,
            is_long: long,
            phase: self.phase,
            scheduled_at: self.scheduled_at.map(rfc3339),
            length_secs,
            started_at: self.started_at.map(rfc3339),
            held_for_meeting: self.held_for_meeting,
        }
    }

    fn cancel_timer(&mut self) -> u64 {
        self.generation += 1;
        if let Some(t) = self.task.take() {
            t.abort();
        }
        self.generation
    }

    /// Schedule `fire` at `at`; zero or past means the caller fires right away.
    fn arm(&mut self, app: &AppHandle, at: DateTime<Utc>) -> u64 {
        let generation = self.cancel_timer();
        self.scheduled_at = Some(at);
        if let Ok(delay) = (at - Utc::now()).to_std()
            && !delay.is_zero()
        {
            let a = app.clone();
            self.task = Some(tauri::async_runtime::spawn(async move {
                tokio::time::sleep(delay).await;
                // Read the calendar now so a meeting added since the last refresh counts.
                crate::calendar::refresh(&a).await;
                fire(&a, generation, true);
            }));
        }
        generation
    }

    fn begin_active(&mut self, s: &Settings) {
        self.cancel_timer();
        self.phase = Phase::Active;
        self.scheduled_at = None;
        self.held_for_meeting = false;
        self.started_at = Some(Utc::now());
        self.active_length =
            break_length(is_long(self.break_index, s.breaks.long.every), &s.breaks);
    }
}

// ---- runtime ----

fn lock<T>(m: &Mutex<T>) -> MutexGuard<'_, T> {
    m.lock().unwrap_or_else(|e| e.into_inner())
}

pub fn settings(app: &AppHandle) -> Settings {
    lock(&app.state::<Mutex<Settings>>()).clone()
}

fn with_scheduler<R>(app: &AppHandle, f: impl FnOnce(&mut Scheduler) -> R) -> R {
    f(&mut lock(&app.state::<Mutex<Scheduler>>()))
}

fn emit_state(app: &AppHandle, state: &BreakState) {
    eprintln!(
        "[scheduler] phase={:?} index={} long={} scheduledAt={:?} length={}",
        state.phase, state.break_index, state.is_long, state.scheduled_at, state.length_secs
    );
    if let Err(e) = app.emit(EVT_BREAK_STATE, state) {
        eprintln!("[scheduler] emit {EVT_BREAK_STATE}: {e}");
    }
}

pub fn get_break_state(app: &AppHandle) -> BreakState {
    let s = settings(app);
    with_scheduler(app, |sch| sch.snapshot(&s))
}

pub fn set_next_break(app: &AppHandle, opts: NextBreakOptions) -> BreakState {
    let s = settings(app);
    let delay = effective_delay(opts.in_secs, s.breaks.every, dev_override());
    let (state, generation) = with_scheduler(app, |sch| {
        sch.break_index = next_break_index(sch.break_index, opts.force_type, s.breaks.long.every);
        sch.phase = Phase::Idle;
        sch.started_at = None;
        sch.skip_before_break = opts.skip_before_break;
        sch.held_for_meeting = false;
        let generation = sch.arm(app, Utc::now() + Duration::from_secs(delay.into()));
        (sch.snapshot(&s), generation)
    });
    // State is already idle, so the destroy hooks see no user skip.
    if !opts.keep_windows {
        on_main(app, "close break windows", windows::close_break_windows);
    }
    emit_state(app, &state);
    // "Now" is the user asking for a break, so a meeting does not hold it.
    if delay == 0 {
        return fire(app, generation, false).unwrap_or(state);
    }
    state
}

enum Fired {
    Held,
    Before,
    Break,
}

/// Timer expiry: open `before-break`, or go straight to the break when `skipBeforeBreak`.
/// With `hold`, a break due during a meeting is re-armed for when it ends instead, keeping
/// its index. No-op when the timer was superseded or the break already fired.
fn fire(app: &AppHandle, generation: u64, hold: bool) -> Option<BreakState> {
    let s = settings(app);
    let held_until = hold
        .then(|| crate::calendar::held_until(app, Utc::now()))
        .flatten();
    let (state, fired) = with_scheduler(app, |sch| {
        if sch.generation != generation || sch.phase != Phase::Idle {
            return None;
        }
        sch.task = None;
        if let Some(at) = held_until {
            sch.held_for_meeting = true;
            sch.arm(app, at);
            return Some((sch.snapshot(&s), Fired::Held));
        }
        sch.held_for_meeting = false;
        if sch.skip_before_break {
            sch.begin_active(&s);
            Some((sch.snapshot(&s), Fired::Break))
        } else {
            sch.phase = Phase::Before;
            Some((sch.snapshot(&s), Fired::Before))
        }
    })?;
    match fired {
        Fired::Held => eprintln!("[scheduler] in a meeting, holding the break"),
        Fired::Break => on_main(app, "open break windows", open_break),
        Fired::Before => on_main(app, "open before-break", windows::open_before_break_window),
    }
    emit_state(app, &state);
    Some(state)
}

fn open_break(app: &AppHandle) -> tauri::Result<()> {
    windows::close_before_break_window(app)?;
    windows::open_cover_windows(app)
}

/// Sleep/wake safety: fire if the wall-clock deadline has passed but the timer has not.
pub async fn check_deadline(app: &AppHandle) {
    let due = with_scheduler(app, |sch| match (sch.phase, sch.scheduled_at) {
        (Phase::Idle, Some(at)) if at <= Utc::now() => Some(sch.generation),
        _ => None,
    });
    if let Some(generation) = due {
        eprintln!("[scheduler] deadline passed without timer (sleep?), firing now");
        crate::calendar::refresh(app).await;
        fire(app, generation, true);
    }
}

pub fn spawn_watchdog(app: &AppHandle) {
    let app = app.clone();
    tauri::async_runtime::spawn(async move {
        let mut tick = tokio::time::interval(WATCHDOG_EVERY);
        loop {
            tick.tick().await;
            check_deadline(&app).await;
        }
    });
}

pub fn start_break(app: &AppHandle) -> BreakState {
    let s = settings(app);
    let state = with_scheduler(app, |sch| {
        sch.begin_active(&s);
        sch.snapshot(&s)
    });
    on_main(app, "open break windows", open_break);
    emit_state(app, &state);
    state
}

pub fn end_break(app: &AppHandle) -> BreakState {
    set_next_break(app, NextBreakOptions::default())
}

pub fn notify_break_ended(app: &AppHandle) {
    if let Err(e) = app.emit(EVT_BREAK_ENDED, serde_json::json!({})) {
        eprintln!("[scheduler] emit {EVT_BREAK_ENDED}: {e}");
    }
}

/// A break window went away. If the app did not close it itself (the phase still says
/// it should be open), the user dismissed it: closing `before-break` skips this break,
/// closing `break` ends it. Both schedule the next one, like legacy's `closed` handler.
pub fn on_window_destroyed(app: &AppHandle, label: &str) {
    let phase = with_scheduler(app, |sch| sch.phase);
    let user_closed = matches!(
        (label, phase),
        (windows::BEFORE_BREAK, Phase::Before) | (windows::BREAK, Phase::Active)
    );
    if user_closed {
        eprintln!("[scheduler] {label} closed by user in phase {phase:?}");
        set_next_break(app, NextBreakOptions::default());
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn index_increments_by_default() {
        assert_eq!(next_break_index(0, None, 3), 1);
        assert_eq!(next_break_index(5, None, 3), 6);
    }

    #[test]
    fn forced_types_reset_index() {
        assert_eq!(next_break_index(7, Some(ForceType::Long), 3), 3);
        assert_eq!(next_break_index(7, Some(ForceType::Short), 3), 1);
    }

    #[test]
    fn forced_long_is_long_and_short_is_short() {
        for every in 1..=30 {
            assert!(is_long(
                next_break_index(9, Some(ForceType::Long), every),
                every
            ));
        }
        for every in 2..=30 {
            assert!(!is_long(
                next_break_index(9, Some(ForceType::Short), every),
                every
            ));
        }
        // every == 1: every break is long, including a forced short one (legacy behaviour).
        assert!(is_long(next_break_index(9, Some(ForceType::Short), 1), 1));
    }

    #[test]
    fn every_third_break_is_long() {
        let pattern: Vec<bool> = (1..=6).map(|i| is_long(i, 3)).collect();
        assert_eq!(pattern, [false, false, true, false, false, true]);
    }

    #[test]
    fn zero_long_every_does_not_panic() {
        assert!(is_long(4, 0));
    }

    #[test]
    fn length_follows_type() {
        let b = Breaks::default();
        assert_eq!(break_length(true, &b), 300);
        assert_eq!(break_length(false, &b), 20);
    }

    #[test]
    fn delay_rules() {
        assert_eq!(effective_delay(None, 1200, None), 1200);
        assert_eq!(effective_delay(Some(60), 1200, None), 60);
        assert_eq!(effective_delay(Some(0), 1200, None), 0);
        assert_eq!(effective_delay(None, 1200, Some(8)), 8);
        assert_eq!(effective_delay(Some(3600), 1200, Some(8)), 8);
        assert_eq!(
            effective_delay(Some(0), 1200, Some(8)),
            0,
            "now stays now in dev"
        );
    }

    #[test]
    fn snapshot_shapes() {
        let s = Settings::default();
        let mut sch = Scheduler::default();
        let st = sch.snapshot(&s);
        assert_eq!(
            (st.break_index, st.is_long, st.phase),
            (0, true, Phase::Idle)
        );
        assert_eq!(st.scheduled_at, None);

        sch.break_index = 1;
        sch.scheduled_at = Some(Utc::now());
        let st = sch.snapshot(&s);
        assert!(!st.is_long);
        assert_eq!(st.length_secs, 20);
        assert!(st.scheduled_at.as_deref().unwrap().ends_with('Z'));

        sch.break_index = 3;
        sch.begin_active(&s);
        let mut changed = s.clone();
        changed.breaks.long.last = 600;
        let st = sch.snapshot(&changed);
        assert_eq!(
            (st.phase, st.is_long, st.length_secs),
            (Phase::Active, true, 300)
        );
        assert!(st.started_at.is_some() && st.scheduled_at.is_none());
    }

    #[test]
    fn begin_active_invalidates_pending_timer() {
        let mut sch = Scheduler::default();
        let g = sch.generation;
        sch.begin_active(&Settings::default());
        assert_ne!(sch.generation, g);
    }

    #[test]
    fn wire_shapes() {
        let st = BreakState {
            break_index: 2,
            is_long: false,
            phase: Phase::Before,
            scheduled_at: Some("2026-11-04T10:00:00.000Z".into()),
            length_secs: 20,
            started_at: None,
            held_for_meeting: false,
        };
        assert_eq!(
            serde_json::to_value(&st).unwrap(),
            serde_json::json!({
                "breakIndex": 2, "isLong": false, "phase": "before",
                "scheduledAt": "2026-11-04T10:00:00.000Z", "lengthSecs": 20, "startedAt": null,
                "heldForMeeting": false
            })
        );
        let o: NextBreakOptions =
            serde_json::from_str(r#"{"inSecs":0,"forceType":"long","skipBeforeBreak":true}"#)
                .unwrap();
        assert_eq!(o.in_secs, Some(0));
        assert_eq!(o.force_type, Some(ForceType::Long));
        assert!(o.skip_before_break && !o.keep_windows);
        let o: NextBreakOptions = serde_json::from_str("{}").unwrap();
        assert!(o.in_secs.is_none() && o.force_type.is_none());
    }
}

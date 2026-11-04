//! Calendar-aware breaks: a cached list of busy intervals read from the macOS calendar
//! store (EventKit). Google, iCloud and Exchange calendars are in that store once the
//! account is added in System Settings → Internet Accounts.
//!
//! The cache is re-read every minute and right before a break fires, so a meeting added
//! a moment ago still holds the break. No access, a failed read or a stale cache all mean
//! "not busy": a calendar problem never stops breaks.

use std::sync::Mutex;
use std::time::Duration;

use chrono::{DateTime, SecondsFormat, TimeDelta, Utc};
use serde::Serialize;
use tauri::{AppHandle, Emitter, Manager};

pub const EVT_CALENDAR_STATUS: &str = "calendar-status";
/// Reading the local calendar store is cheap; a minute keeps the menu's meeting line fresh.
pub const REFRESH_EVERY: Duration = Duration::from_secs(60);
/// A cache older than this is ignored (refresh loop stalled, Mac asleep).
const STALE_AFTER: TimeDelta = TimeDelta::minutes(30);
/// A held break fires this long after the meeting ends. Meetings that start within this
/// gap count as one block.
pub const GRACE: TimeDelta = TimeDelta::minutes(1);
const LOOK_BACK: TimeDelta = TimeDelta::hours(12);
const LOOK_AHEAD: TimeDelta = TimeDelta::hours(12);

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Interval {
    pub start: DateTime<Utc>,
    pub end: DateTime<Utc>,
}

/// One busy calendar event.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Busy {
    pub interval: Interval,
    pub title: String,
}

/// What EventKit tells us about one event, reduced to what decides "busy".
#[derive(Debug, Clone)]
pub struct EventInfo {
    pub interval: Interval,
    pub title: String,
    pub all_day: bool,
    /// Availability set to "free" (Google: "Show as available").
    pub free: bool,
    pub canceled: bool,
    /// The current user is an attendee and declined.
    pub declined: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum Access {
    NotDetermined,
    Granted,
    Denied,
    Restricted,
    /// Not macOS.
    #[cfg_attr(target_os = "macos", allow(dead_code))]
    Unsupported,
}

/// The meeting going on now and when the busy block it belongs to ends.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Meeting {
    pub title: String,
    pub until: DateTime<Utc>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct MeetingWire {
    pub title: String,
    pub until: String,
}

/// Wire shape of `get_calendar_status`, `set_calendar_enabled` and the
/// `calendar-status` event.
#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct CalendarStatus {
    pub enabled: bool,
    pub access: Access,
    pub meeting: Option<MeetingWire>,
    pub synced_at: Option<String>,
}

#[derive(Default)]
pub struct Calendar {
    busy: Vec<Busy>,
    fetched_at: Option<DateTime<Utc>>,
}

// ---- pure rules (unit tested) ----

/// Timed, busy, not canceled and not declined. Everything else is ignored.
pub fn busy_events(events: impl IntoIterator<Item = EventInfo>) -> Vec<Busy> {
    events
        .into_iter()
        .filter(|e| !e.all_day && !e.free && !e.canceled && !e.declined)
        .filter(|e| e.interval.end > e.interval.start)
        .map(|e| Busy {
            interval: e.interval,
            title: e.title,
        })
        .collect()
}

/// The earliest-started meeting covering `now`, with the end of its busy block: meetings
/// that start within `GRACE` of the previous one ending are merged. `None` when free.
pub fn current_meeting(busy: &[Busy], now: DateTime<Utc>) -> Option<Meeting> {
    let mut upcoming: Vec<_> = busy.iter().filter(|b| b.interval.end > now).collect();
    upcoming.sort_by_key(|b| b.interval.start);
    let mut meeting: Option<Meeting> = None;
    for b in upcoming {
        let i = b.interval;
        match &mut meeting {
            None if i.start <= now => {
                meeting = Some(Meeting {
                    title: b.title.clone(),
                    until: i.end,
                })
            }
            Some(m) if i.start <= m.until + GRACE => m.until = m.until.max(i.end),
            _ => break,
        }
    }
    meeting
}

fn rfc3339(t: DateTime<Utc>) -> String {
    t.to_rfc3339_opts(SecondsFormat::Millis, true)
}

// ---- runtime ----

fn lock(app: &AppHandle) -> std::sync::MutexGuard<'_, Calendar> {
    app.state::<Mutex<Calendar>>()
        .inner()
        .lock()
        .unwrap_or_else(|e| e.into_inner())
}

fn enabled(app: &AppHandle) -> bool {
    crate::scheduler::settings(app).calendar.enabled
}

/// The meeting going on at `now` per a fresh cache, if the feature is on.
fn meeting_now(app: &AppHandle, now: DateTime<Utc>) -> Option<Meeting> {
    if !enabled(app) {
        return None;
    }
    let cal = lock(app);
    match cal.fetched_at {
        Some(at) if now - at <= STALE_AFTER => current_meeting(&cal.busy, now),
        _ => None,
    }
}

/// When a break due at `now` should fire instead, or `None` to fire now.
pub fn held_until(app: &AppHandle, now: DateTime<Utc>) -> Option<DateTime<Utc>> {
    let meeting = meeting_now(app, now)?;
    eprintln!("[calendar] in a meeting until {}", rfc3339(meeting.until));
    Some(meeting.until + GRACE)
}

pub fn status(app: &AppHandle) -> CalendarStatus {
    let now = Utc::now();
    let meeting = meeting_now(app, now).map(|m| MeetingWire {
        title: m.title,
        until: rfc3339(m.until),
    });
    let enabled = enabled(app);
    let synced_at = lock(app).fetched_at.map(rfc3339);
    CalendarStatus {
        enabled,
        access: eventkit::access(),
        meeting,
        synced_at,
    }
}

/// Ask macOS for calendar access if it was never asked. Blocks until the user answers.
pub async fn request_access() -> Access {
    match eventkit::access() {
        Access::NotDetermined => tauri::async_runtime::spawn_blocking(eventkit::request_access)
            .await
            .unwrap_or(Access::Denied),
        other => other,
    }
}

/// Re-read busy events into the cache (cleared when disabled or unreadable) and
/// broadcast the new status.
pub async fn refresh(app: &AppHandle) {
    let fetched = if enabled(app) {
        let now = Utc::now();
        tauri::async_runtime::spawn_blocking(move || match eventkit::access() {
            Access::Granted => Some(busy_events(eventkit::events(
                now - LOOK_BACK,
                now + LOOK_AHEAD,
            ))),
            access => {
                eprintln!("[calendar] no calendar access ({access:?}), breaks are not held");
                None
            }
        })
        .await
        .ok()
        .flatten()
    } else {
        None
    };
    {
        let mut cal = lock(app);
        match fetched {
            Some(busy) => {
                eprintln!("[calendar] {} busy event(s) around now", busy.len());
                if cfg!(debug_assertions) {
                    for b in &busy {
                        let (s, e) = (rfc3339(b.interval.start), rfc3339(b.interval.end));
                        eprintln!("[calendar] busy {s} – {e} {:?}", b.title);
                    }
                }
                cal.busy = busy;
                cal.fetched_at = Some(Utc::now());
            }
            None => *cal = Calendar::default(),
        }
    }
    if let Err(e) = app.emit(EVT_CALENDAR_STATUS, status(app)) {
        eprintln!("[calendar] emit {EVT_CALENDAR_STATUS}: {e}");
    }
}

/// Refresh every `REFRESH_EVERY`. When the feature is on but macOS has never been asked
/// (e.g. a rebuilt, re-signed dev app lost its grant), ask first.
pub fn spawn_refresher(app: &AppHandle) {
    let app = app.clone();
    tauri::async_runtime::spawn(async move {
        if enabled(&app) {
            request_access().await;
        }
        let mut tick = tokio::time::interval(REFRESH_EVERY);
        loop {
            tick.tick().await;
            refresh(&app).await;
        }
    });
}

/// System Settings → Privacy & Security → Calendars.
pub fn open_privacy_settings() {
    #[cfg(target_os = "macos")]
    if let Err(e) = std::process::Command::new("open")
        .arg("x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")
        .spawn()
    {
        eprintln!("[calendar] open privacy settings: {e}");
    }
}

#[cfg(target_os = "macos")]
mod eventkit {
    //! EventKit calls. A fresh `EKEventStore` per call: it is not `Send`, calls are rare
    //! (every few minutes), and a new store sees access granted after it was created.

    use std::sync::mpsc;

    use block2::RcBlock;
    use chrono::{DateTime, Utc};
    use objc2::runtime::Bool;
    use objc2::sel;
    use objc2_event_kit::{
        EKAuthorizationStatus, EKEntityType, EKEventAvailability, EKEventStatus, EKEventStore,
        EKParticipantStatus,
    };
    use objc2_foundation::{NSDate, NSError, NSObjectProtocol};

    use super::{Access, EventInfo, Interval};

    pub fn access() -> Access {
        // SAFETY: class method with a valid entity type.
        let status = unsafe { EKEventStore::authorizationStatusForEntityType(EKEntityType::Event) };
        match status {
            EKAuthorizationStatus::NotDetermined => Access::NotDetermined,
            EKAuthorizationStatus::FullAccess => Access::Granted,
            EKAuthorizationStatus::Restricted => Access::Restricted,
            // Write-only access cannot read events.
            _ => Access::Denied,
        }
    }

    pub fn request_access() -> Access {
        // SAFETY: plain allocation.
        let store = unsafe { EKEventStore::new() };
        let (tx, rx) = mpsc::channel();
        let block = RcBlock::new(move |granted: Bool, _err: *mut NSError| {
            let _ = tx.send(granted.as_bool());
        });
        // SAFETY: `block` and `store` outlive the call; the completion may run on any
        // thread and only sends on a channel.
        unsafe {
            if store.respondsToSelector(sel!(requestFullAccessToEventsWithCompletion:)) {
                store.requestFullAccessToEventsWithCompletion(RcBlock::as_ptr(&block));
            } else {
                // macOS 12-13.
                #[allow(deprecated)]
                store.requestAccessToEntityType_completion(
                    EKEntityType::Event,
                    RcBlock::as_ptr(&block),
                );
            }
        }
        let granted = rx.recv().unwrap_or(false);
        eprintln!("[calendar] access request answered: granted={granted}");
        access()
    }

    fn ns_date(t: DateTime<Utc>) -> objc2::rc::Retained<NSDate> {
        NSDate::dateWithTimeIntervalSince1970(t.timestamp_millis() as f64 / 1000.0)
    }

    fn utc(d: &NSDate) -> Option<DateTime<Utc>> {
        DateTime::from_timestamp_millis((d.timeIntervalSince1970() * 1000.0) as i64)
    }

    pub fn events(from: DateTime<Utc>, to: DateTime<Utc>) -> Vec<EventInfo> {
        // SAFETY: EventKit getters on objects owned by this store, used on this thread only.
        unsafe {
            let store = EKEventStore::new();
            let predicate = store.predicateForEventsWithStartDate_endDate_calendars(
                &ns_date(from),
                &ns_date(to),
                None,
            );
            store
                .eventsMatchingPredicate(&predicate)
                .iter()
                .filter_map(|e| {
                    let interval = Interval {
                        start: utc(&e.startDate())?,
                        end: utc(&e.endDate())?,
                    };
                    let declined = e.attendees().is_some_and(|people| {
                        people.iter().any(|p| {
                            p.isCurrentUser()
                                && p.participantStatus() == EKParticipantStatus::Declined
                        })
                    });
                    Some(EventInfo {
                        interval,
                        title: e.title().to_string(),
                        all_day: e.isAllDay(),
                        free: e.availability() == EKEventAvailability::Free,
                        canceled: e.status() == EKEventStatus::Canceled,
                        declined,
                    })
                })
                .collect()
        }
    }
}

#[cfg(not(target_os = "macos"))]
mod eventkit {
    use chrono::{DateTime, Utc};

    use super::{Access, EventInfo};

    pub fn access() -> Access {
        Access::Unsupported
    }

    pub fn request_access() -> Access {
        Access::Unsupported
    }

    pub fn events(_from: DateTime<Utc>, _to: DateTime<Utc>) -> Vec<EventInfo> {
        Vec::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn at(min: i64) -> DateTime<Utc> {
        DateTime::from_timestamp(1_800_000_000, 0).unwrap() + TimeDelta::minutes(min)
    }

    fn iv(start: i64, end: i64) -> Interval {
        Interval {
            start: at(start),
            end: at(end),
        }
    }

    fn busy(start: i64, end: i64, title: &str) -> Busy {
        Busy {
            interval: iv(start, end),
            title: title.into(),
        }
    }

    fn event(start: i64, end: i64) -> EventInfo {
        EventInfo {
            interval: iv(start, end),
            title: "Sync".into(),
            all_day: false,
            free: false,
            canceled: false,
            declined: false,
        }
    }

    fn until(day: &[Busy], now: i64) -> Option<DateTime<Utc>> {
        current_meeting(day, at(now)).map(|m| m.until)
    }

    #[test]
    fn free_time_is_not_busy() {
        assert_eq!(until(&[], 0), None);
        assert_eq!(until(&[busy(10, 40, "later")], 0), None);
        assert_eq!(until(&[busy(-40, -10, "over")], 0), None);
        assert_eq!(until(&[busy(-30, 0, "ends now")], 0), None);
    }

    #[test]
    fn inside_a_meeting() {
        assert_eq!(
            current_meeting(&[busy(-10, 20, "Standup")], at(0)),
            Some(Meeting {
                title: "Standup".into(),
                until: at(20)
            })
        );
        assert_eq!(until(&[busy(0, 30, "starts now")], 0), Some(at(30)));
    }

    #[test]
    fn back_to_back_meetings_merge() {
        let day = [
            busy(30, 60, "c"),
            busy(-10, 30, "a"),
            busy(31, 45, "d"),
            busy(70, 90, "e"),
        ];
        let m = current_meeting(&day, at(0)).unwrap();
        assert_eq!((m.title.as_str(), m.until), ("a", at(60)));
    }

    #[test]
    fn overlapping_meetings_take_the_latest_end() {
        let m = current_meeting(&[busy(-5, 20, "b"), busy(-10, 50, "a")], at(0)).unwrap();
        assert_eq!((m.title.as_str(), m.until), ("a", at(50)));
    }

    #[test]
    fn a_real_gap_ends_the_block() {
        assert_eq!(
            until(&[busy(-10, 20, "a"), busy(25, 60, "b")], 0),
            Some(at(20))
        );
    }

    #[test]
    fn only_busy_timed_events_count() {
        let mut all_day = event(-60, 60);
        all_day.all_day = true;
        let mut free = event(-60, 60);
        free.free = true;
        let mut canceled = event(-60, 60);
        canceled.canceled = true;
        let mut declined = event(-60, 60);
        declined.declined = true;
        let zero = event(0, 0);
        let found = busy_events([all_day, free, canceled, declined, zero, event(-5, 5)]);
        assert_eq!(found, vec![busy(-5, 5, "Sync")]);
    }

    #[test]
    fn status_wire_shape() {
        let st = CalendarStatus {
            enabled: true,
            access: Access::Granted,
            meeting: Some(MeetingWire {
                title: "Standup".into(),
                until: "2026-11-04T10:30:00.000Z".into(),
            }),
            synced_at: Some("2026-11-04T10:00:00.000Z".into()),
        };
        assert_eq!(
            serde_json::to_value(&st).unwrap(),
            serde_json::json!({
                "enabled": true, "access": "granted",
                "meeting": { "title": "Standup", "until": "2026-11-04T10:30:00.000Z" },
                "syncedAt": "2026-11-04T10:00:00.000Z"
            })
        );
    }
}

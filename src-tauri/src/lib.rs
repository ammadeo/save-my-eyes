mod commands;
mod macos;
mod scheduler;
mod settings;
mod tray;
mod windows;

use std::sync::Mutex;

use tauri::{AppHandle, Manager, RunEvent};
use tauri_plugin_autostart::{MacosLauncher, ManagerExt as _};
use tauri_plugin_notification::NotificationExt as _;

use scheduler::{NextBreakOptions, Scheduler};
use settings::{Lang, Settings};

/// "20 minutes" / "20 minut", floored like legacy `formatDistanceStrict`.
fn format_duration(secs: i64, lang: Lang) -> String {
    let (n, unit) = if secs < 60 {
        (secs.max(0), 0)
    } else {
        (secs / 60, 1)
    };
    let word = match lang {
        Lang::En => match (unit, n == 1) {
            (0, true) => "second",
            (0, false) => "seconds",
            (_, true) => "minute",
            (_, false) => "minutes",
        },
        Lang::Pl => {
            let few = (2..=4).contains(&(n % 10)) && !(12..=14).contains(&(n % 100));
            match (unit, n == 1, few) {
                (0, true, _) => "sekunda",
                (0, _, true) => "sekundy",
                (0, _, _) => "sekund",
                (_, true, _) => "minuta",
                (_, _, true) => "minuty",
                _ => "minut",
            }
        }
    };
    format!("{n} {word}")
}

/// Startup balloon from legacy `tray.ts`.
fn startup_message(lang: Lang, secs: i64) -> String {
    let next = format_duration(secs, lang);
    match lang {
        Lang::En => format!("Your eyes are protected. Next break will start in {next}."),
        Lang::Pl => format!("Dbamy o Twoje oczy. Następna przerwa rozpocznie się za {next}."),
    }
}

fn notify_started(app: &AppHandle, lang: Lang, scheduled_at: Option<&str>) {
    let secs = scheduled_at
        .and_then(|t| chrono::DateTime::parse_from_rfc3339(t).ok())
        .map(|t| (t.timestamp_millis() - chrono::Utc::now().timestamp_millis() + 500) / 1000)
        .unwrap_or(0);
    let res = app
        .notification()
        .builder()
        .title("Save My Eyes")
        .body(startup_message(lang, secs))
        .show();
    if let Err(e) = res {
        eprintln!("[startup] notification: {e}");
    }
}

fn enable_autostart(app: &AppHandle) {
    // A debug binary inside a worktree must not become a login item; opt in explicitly.
    if cfg!(debug_assertions) && std::env::var_os("SME_DEV_AUTOSTART").is_none() {
        eprintln!("[startup] autostart skipped in debug build (set SME_DEV_AUTOSTART=1 to test)");
        return;
    }
    let launcher = app.autolaunch();
    match launcher.is_enabled() {
        Ok(true) => {}
        _ => {
            if let Err(e) = launcher.enable() {
                eprintln!("[startup] autostart: {e}");
            }
        }
    }
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_notification::init())
        .plugin(tauri_plugin_autostart::init(
            MacosLauncher::LaunchAgent,
            None,
        ))
        .invoke_handler(tauri::generate_handler![
            commands::get_settings,
            commands::set_settings,
            commands::get_break_state,
            commands::set_next_break,
            commands::start_break,
            commands::notify_break_ended,
            commands::end_break,
            commands::close_window,
            commands::quit_app,
        ])
        .setup(|app| {
            let handle = app.handle().clone();
            let path = settings::settings_path(&handle)?;
            let settings = Settings::load_from(&path);
            eprintln!("[startup] settings from {}: {settings:?}", path.display());
            let lang = settings.lang;
            app.manage(Mutex::new(settings));
            app.manage(Mutex::new(Scheduler::default()));

            macos::hide_from_dock(&handle);
            tray::build_tray(&handle, lang)?;
            enable_autostart(&handle);
            let state = scheduler::set_next_break(&handle, NextBreakOptions::default());
            scheduler::spawn_watchdog(&handle);
            notify_started(&handle, lang, state.scheduled_at.as_deref());
            Ok(())
        })
        .build(tauri::generate_context!())
        .expect("error while building tauri application")
        .run(|app, event| match event {
            // Menu-bar agent: closing the last window must not quit the app.
            RunEvent::ExitRequested {
                api, code: None, ..
            } => api.prevent_exit(),
            RunEvent::Resumed => scheduler::check_deadline(app),
            _ => {}
        });
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn durations_en() {
        assert_eq!(format_duration(1200, Lang::En), "20 minutes");
        assert_eq!(format_duration(119, Lang::En), "1 minute");
        assert_eq!(format_duration(8, Lang::En), "8 seconds");
    }

    #[test]
    fn durations_pl() {
        assert_eq!(format_duration(60, Lang::Pl), "1 minuta");
        assert_eq!(format_duration(22 * 60, Lang::Pl), "22 minuty");
        assert_eq!(format_duration(12 * 60, Lang::Pl), "12 minut");
        assert_eq!(format_duration(20 * 60, Lang::Pl), "20 minut");
        assert_eq!(format_duration(8, Lang::Pl), "8 sekund");
        assert_eq!(format_duration(3, Lang::Pl), "3 sekundy");
    }

    #[test]
    fn startup_messages() {
        assert_eq!(
            startup_message(Lang::En, 1200),
            "Your eyes are protected. Next break will start in 20 minutes."
        );
        assert_eq!(
            startup_message(Lang::Pl, 1200),
            "Dbamy o Twoje oczy. Następna przerwa rozpocznie się za 20 minut."
        );
    }
}

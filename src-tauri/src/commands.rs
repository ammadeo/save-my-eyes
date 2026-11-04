//! Tauri commands: the whole webview → Rust contract (docs/migration/PLAN.md, "IPC contract").

use std::sync::Mutex;

use serde::Serialize;
use tauri::{AppHandle, Emitter, Manager, WebviewWindow};

use crate::scheduler::{self, BreakState, NextBreakOptions};
use crate::settings::{self, Fix, Settings};
use crate::{tray, windows};

pub const EVT_SETTINGS_CHANGED: &str = "settings-changed";

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct SetSettingsResult {
    pub settings: Settings,
    pub fixes: Vec<Fix>,
}

#[tauri::command]
pub async fn get_settings(app: AppHandle) -> Settings {
    scheduler::settings(&app)
}

/// Validate (clamp), persist and broadcast. Does not reschedule: the frontend calls
/// `set_next_break({ keepWindows: true })` when the cadence changed.
#[tauri::command]
pub async fn set_settings(
    app: AppHandle,
    mut settings: Settings,
) -> Result<SetSettingsResult, String> {
    let fixes = settings.validate();
    let old_lang = {
        let state = app.state::<Mutex<Settings>>();
        let mut current = state.lock().unwrap_or_else(|e| e.into_inner());
        std::mem::replace(&mut *current, settings.clone()).lang
    };
    let path = settings::settings_path(&app).map_err(|e| e.to_string())?;
    settings
        .save_to(&path)
        .map_err(|e| format!("saving {}: {e}", path.display()))?;
    if old_lang != settings.lang {
        let (a, lang) = (app.clone(), settings.lang);
        windows::on_main(&app, "relabel tray menu", move |_| {
            tray::set_language(&a, lang);
            Ok(())
        });
    }
    if let Err(e) = app.emit(EVT_SETTINGS_CHANGED, &settings) {
        eprintln!("[commands] emit {EVT_SETTINGS_CHANGED}: {e}");
    }
    Ok(SetSettingsResult { settings, fixes })
}

#[tauri::command]
pub async fn get_break_state(app: AppHandle) -> BreakState {
    scheduler::get_break_state(&app)
}

#[tauri::command]
pub async fn set_next_break(app: AppHandle, opts: Option<NextBreakOptions>) -> BreakState {
    scheduler::set_next_break(&app, opts.unwrap_or_default())
}

#[tauri::command]
pub async fn start_break(app: AppHandle) -> BreakState {
    scheduler::start_break(&app)
}

#[tauri::command]
pub async fn notify_break_ended(app: AppHandle) {
    scheduler::notify_break_ended(&app)
}

#[tauri::command]
pub async fn end_break(app: AppHandle) -> BreakState {
    scheduler::end_break(&app)
}

/// Destroy the calling window. Closing `before-break` while it is showing is a skip and
/// closing `break` mid-break ends it; both are handled by the windows' destroy hooks
/// (`scheduler::on_window_destroyed`) so native close / Cmd+W behave the same.
#[tauri::command]
pub async fn close_window(window: WebviewWindow) {
    let app = window.app_handle().clone();
    windows::on_main(&app, "close_window", move |_| window.destroy());
}

#[tauri::command]
pub async fn quit_app(app: AppHandle) {
    app.exit(0)
}

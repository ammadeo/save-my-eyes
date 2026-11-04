//! Menu-bar tray icon. Left click opens the `menu` window.

use tauri::tray::{MouseButton, MouseButtonState, TrayIcon, TrayIconBuilder, TrayIconEvent};
use tauri::AppHandle;

use crate::windows;

pub fn build_tray(app: &AppHandle) -> tauri::Result<TrayIcon> {
    let mut b = TrayIconBuilder::with_id("main")
        .tooltip("Save My Eyes")
        .show_menu_on_left_click(false)
        .on_tray_icon_event(|tray, event| {
            if let TrayIconEvent::Click {
                button: MouseButton::Left,
                button_state: MouseButtonState::Up,
                ..
            } = event
            {
                on_left_click(tray.app_handle());
            }
        });
    if let Some(icon) = app.default_window_icon() {
        b = b.icon(icon.clone());
    }
    b.build(app)
}

/// The tray left-click handler. Runs on the main thread.
pub fn on_left_click(app: &AppHandle) {
    if let Err(e) = windows::open_menu_window(app) {
        eprintln!("open_menu_window: {e}");
    }
}

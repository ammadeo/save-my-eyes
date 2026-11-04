//! Menu-bar tray icon: left click opens the `menu` window, right click shows a native menu.

use tauri::menu::{Menu, MenuBuilder, MenuEvent};
use tauri::tray::{MouseButton, MouseButtonState, TrayIcon, TrayIconBuilder, TrayIconEvent};
use tauri::{AppHandle, Wry};

use crate::scheduler::{self, ForceType, NextBreakOptions};
use crate::settings::Lang;
use crate::windows;

const TRAY_ID: &str = "main";
const ITEM_OPEN: &str = "open";
const ITEM_LONG_BREAK: &str = "long-break";
const ITEM_QUIT: &str = "quit";

fn build_menu(app: &AppHandle, lang: Lang) -> tauri::Result<Menu<Wry>> {
    let (open, long_break, quit) = match lang {
        Lang::En => ("Open Save My Eyes", "Start long break now", "Quit"),
        Lang::Pl => (
            "Otwórz Save My Eyes",
            "Rozpocznij długą przerwę teraz",
            "Zakończ",
        ),
    };
    MenuBuilder::new(app)
        .text(ITEM_OPEN, open)
        .text(ITEM_LONG_BREAK, long_break)
        .separator()
        .text(ITEM_QUIT, quit)
        .build()
}

pub fn build_tray(app: &AppHandle, lang: Lang) -> tauri::Result<TrayIcon> {
    TrayIconBuilder::with_id(TRAY_ID)
        .icon(tauri::include_image!("icons/tray@2x.png"))
        .icon_as_template(true)
        .tooltip("Save My Eyes")
        .menu(&build_menu(app, lang)?)
        .show_menu_on_left_click(false)
        .on_menu_event(on_menu_event)
        .on_tray_icon_event(|tray, event| {
            if let TrayIconEvent::Click {
                button: MouseButton::Left,
                button_state: MouseButtonState::Up,
                ..
            } = event
            {
                open_menu(tray.app_handle());
            }
        })
        .build(app)
}

/// Re-label the native menu after a language change.
pub fn set_language(app: &AppHandle, lang: Lang) {
    let Some(tray) = app.tray_by_id(TRAY_ID) else {
        return;
    };
    match build_menu(app, lang) {
        Ok(menu) => {
            if let Err(e) = tray.set_menu(Some(menu)) {
                eprintln!("[tray] set_menu: {e}");
            }
        }
        Err(e) => eprintln!("[tray] build_menu: {e}"),
    }
}

/// Runs on the main thread.
fn open_menu(app: &AppHandle) {
    if let Err(e) = windows::open_menu_window(app) {
        eprintln!("[tray] open_menu_window: {e}");
    }
}

fn on_menu_event(app: &AppHandle, event: MenuEvent) {
    match event.id().as_ref() {
        ITEM_OPEN => open_menu(app),
        ITEM_LONG_BREAK => {
            let app = app.clone();
            tauri::async_runtime::spawn(async move {
                scheduler::set_next_break(
                    &app,
                    NextBreakOptions {
                        in_secs: Some(0),
                        force_type: Some(ForceType::Long),
                        skip_before_break: true,
                        keep_windows: false,
                    },
                );
            });
        }
        ITEM_QUIT => app.exit(0),
        _ => {}
    }
}

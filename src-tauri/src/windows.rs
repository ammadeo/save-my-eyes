//! Window lifecycle. All windows are created here at runtime; `tauri.conf.json` has none.

use tauri::window::Color;
use tauri::{
    AppHandle, LogicalSize, Manager, Monitor, PhysicalPosition, WebviewUrl, WebviewWindow,
    WebviewWindowBuilder, WindowEvent,
};

use crate::macos;

pub const BREAK: &str = "break";
pub const MENU: &str = "menu";
const COVER_PREFIX: &str = "cover-";
const COVER_BG: Color = Color(0x12, 0x19, 0x59, 0xff);
const MENU_SIZE: LogicalSize<f64> = LogicalSize::new(420.0, 560.0);
const MENU_MARGIN: f64 = 12.0;

fn route(r: &str) -> WebviewUrl {
    WebviewUrl::App(format!("index.html#/{r}").into())
}

/// Frameless window sized to `monitor`'s physical bounds (not `fullscreen`, which makes a new Space).
fn build_cover(app: &AppHandle, label: &str, r: &str, monitor: &Monitor) -> tauri::Result<WebviewWindow> {
    let w = WebviewWindowBuilder::new(app, label, route(r))
        .title("Save My Eyes")
        .decorations(false)
        .resizable(false)
        .always_on_top(true)
        .visible_on_all_workspaces(true)
        .shadow(false)
        .background_color(COVER_BG)
        .visible(false)
        .build()?;
    w.set_position(*monitor.position())?;
    w.set_size(*monitor.size())?;
    macos::elevate_cover_window(&w)?;
    w.show()?;
    Ok(w)
}

/// Open `break` on the primary monitor and `cover-N` on every other monitor. Idempotent.
/// Call on the main thread.
pub fn open_cover_windows(app: &AppHandle) -> tauri::Result<()> {
    if app.get_webview_window(BREAK).is_some() {
        return Ok(());
    }
    let monitors = app.available_monitors()?;
    let Some(primary) = app.primary_monitor()?.or_else(|| monitors.first().cloned()) else {
        return Ok(());
    };
    let w = build_cover(app, BREAK, "break", &primary)?;
    w.set_focus()?;
    let externals = monitors.iter().filter(|m| m.position() != primary.position());
    for (i, m) in externals.enumerate() {
        build_cover(app, &format!("{COVER_PREFIX}{i}"), "blank", m)?;
    }
    Ok(())
}

pub fn close_cover_windows(app: &AppHandle) -> tauri::Result<()> {
    for (label, w) in app.webview_windows() {
        if label == BREAK || label.starts_with(COVER_PREFIX) {
            w.destroy()?;
        }
    }
    Ok(())
}

/// Card-sized window with native chrome (traffic lights over the page, hidden title),
/// top-right of the primary work area under the tray icon; closes on blur, close button, Cmd+W.
pub fn open_menu_window(app: &AppHandle) -> tauri::Result<()> {
    if let Some(w) = app.get_webview_window(MENU) {
        w.show()?;
        return w.set_focus();
    }
    let b = WebviewWindowBuilder::new(app, MENU, route("menu"))
        .title("Save My Eyes")
        .decorations(true)
        .resizable(false)
        .minimizable(false)
        .always_on_top(true)
        .inner_size(MENU_SIZE.width, MENU_SIZE.height)
        .visible(false);
    #[cfg(target_os = "macos")]
    let b = b.title_bar_style(tauri::TitleBarStyle::Overlay).hidden_title(true);
    let w = b.build()?;
    if let Some(m) = app.primary_monitor()? {
        let area = m.work_area();
        let width = (MENU_SIZE.width * m.scale_factor()) as i32;
        let margin = (MENU_MARGIN * m.scale_factor()) as i32;
        w.set_position(PhysicalPosition::new(
            area.position.x + area.size.width as i32 - width - margin,
            area.position.y + margin,
        ))?;
    }
    let handle = w.clone();
    w.on_window_event(move |e| {
        if let WindowEvent::Focused(false) = e {
            let _ = handle.destroy();
        }
    });
    w.show()?;
    w.set_focus()
}

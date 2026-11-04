//! Window lifecycle. All windows are created here at runtime; `tauri.conf.json` has none.
//!
//! Every `open_*`/`close_*` function touches AppKit and must run on the main thread
//! (`setup`, tray handlers, or via [`on_main`]).

use tauri::utils::config::WindowEffectsConfig;
use tauri::window::{Color, Effect};
use tauri::{
    AppHandle, LogicalSize, Manager, Monitor, PhysicalPosition, WebviewUrl, WebviewWindow,
    WebviewWindowBuilder, WindowEvent,
};

use crate::{macos, scheduler};

pub const MENU: &str = "menu";
pub const BEFORE_BREAK: &str = "before-break";
pub const BREAK: &str = "break";
pub const COVER_PREFIX: &str = "cover-";

/// Initial size; the page resizes the window per pane (`MenuView.vue`, `paneHeight`).
const MENU_SIZE: LogicalSize<f64> = LogicalSize::new(400.0, 352.0);
/// Initial size; the page resizes the card to its content (`BeforeBreakView.vue`).
const BEFORE_BREAK_SIZE: LogicalSize<f64> = LogicalSize::new(360.0, 100.0);
/// Logical-pixel gap between a card window and the work-area edges.
const MARGIN: f64 = 12.0;
/// Corner radius of the `before-break` card; `macos::style_panel` clips to the same value.
pub const PANEL_RADIUS: f64 = 18.0;
/// Sage glass tint (~0.14 alpha), DESIGN.md `glass-tint`.
const GLASS_TINT: Color = Color(122, 158, 134, 36);

/// The native material painted behind every (transparent) window.
///
/// macOS 26+: Liquid Glass (`NSGlassEffectView`, regular style) tinted sage, with `radius`
/// as the glass corner radius. macOS 15 and below: the `fallback` `NSVisualEffectView`
/// material instead (the tint is glass-only; `radius` still rounds it).
/// Requires `.transparent(true)` on the builder so the webview does not paint over it.
fn material(fallback: Effect, radius: Option<f64>) -> WindowEffectsConfig {
    WindowEffectsConfig {
        effects: vec![Effect::LiquidGlassRegular, fallback],
        state: None,
        radius,
        color: Some(GLASS_TINT),
        interactive: false,
    }
}

fn route(r: &str) -> WebviewUrl {
    WebviewUrl::App(format!("index.html#/{r}").into())
}

/// Run `f` on the main thread, logging (not propagating) window errors.
/// Runs inline when already on the main thread.
pub fn on_main(
    app: &AppHandle,
    what: &'static str,
    f: impl FnOnce(&AppHandle) -> tauri::Result<()> + Send + 'static,
) {
    let a = app.clone();
    let res = app.run_on_main_thread(move || {
        if let Err(e) = f(&a) {
            eprintln!("[windows] {what} failed: {e}");
        }
    });
    if let Err(e) = res {
        eprintln!("[windows] {what}: could not reach main thread: {e}");
    }
}

/// Physical top-left for a `size` (logical) card in the top-right corner of the primary work area.
fn top_right(
    app: &AppHandle,
    size: LogicalSize<f64>,
) -> tauri::Result<Option<PhysicalPosition<i32>>> {
    let Some(m) = app.primary_monitor()? else {
        return Ok(None);
    };
    let area = m.work_area();
    let scale = m.scale_factor();
    let width = (size.width * scale) as i32;
    let margin = (MARGIN * scale) as i32;
    Ok(Some(PhysicalPosition::new(
        area.position.x + area.size.width as i32 - width - margin,
        area.position.y + margin,
    )))
}

/// Tell the scheduler when the user (not the app) closed a break window: native close,
/// Cmd+W or `close_window`. Deferred to a task so the scheduler never re-enters the
/// event loop from inside a window event.
fn notify_destroyed(w: &WebviewWindow) {
    let app = w.app_handle().clone();
    let label = w.label().to_string();
    w.on_window_event(move |e| {
        if let WindowEvent::Destroyed = e {
            let app = app.clone();
            let label = label.clone();
            tauri::async_runtime::spawn(
                async move { scheduler::on_window_destroyed(&app, &label) },
            );
        }
    });
}

/// Frameless window sized to `monitor`'s physical bounds (not `fullscreen`, which makes a new Space).
fn build_cover(
    app: &AppHandle,
    label: &str,
    r: &str,
    monitor: &Monitor,
) -> tauri::Result<WebviewWindow> {
    let w = WebviewWindowBuilder::new(app, label, route(r))
        .title("Save My Eyes")
        .decorations(false)
        .resizable(false)
        .always_on_top(true)
        .visible_on_all_workspaces(true)
        .shadow(false)
        .transparent(true)
        .effects(material(Effect::FullScreenUI, None))
        .visible(false)
        .build()?;
    w.set_position(*monitor.position())?;
    w.set_size(*monitor.size())?;
    macos::elevate_cover_window(&w)?;
    w.show()?;
    Ok(w)
}

/// Open `break` on the primary monitor and `cover-N` on every other monitor, focus `break`.
/// Idempotent.
pub fn open_cover_windows(app: &AppHandle) -> tauri::Result<()> {
    if let Some(w) = app.get_webview_window(BREAK) {
        return w.set_focus();
    }
    let monitors = app.available_monitors()?;
    let Some(primary) = app.primary_monitor()?.or_else(|| monitors.first().cloned()) else {
        return Ok(());
    };
    let w = build_cover(app, BREAK, "break", &primary)?;
    notify_destroyed(&w);
    let externals = monitors
        .iter()
        .filter(|m| m.position() != primary.position());
    for (i, m) in externals.enumerate() {
        build_cover(app, &format!("{COVER_PREFIX}{i}"), "blank", m)?;
    }
    macos::activate_app();
    w.set_focus()
}

/// Notification-style card top-right of the primary work area. Does not take focus.
pub fn open_before_break_window(app: &AppHandle) -> tauri::Result<()> {
    if app.get_webview_window(BEFORE_BREAK).is_some() {
        return Ok(());
    }
    // Both windows live top-right; the banner takes precedence over an open menu.
    destroy_where(app, |l| l == MENU)?;
    let mut b = WebviewWindowBuilder::new(app, BEFORE_BREAK, route("before-break"))
        .title("Save My Eyes")
        .inner_size(BEFORE_BREAK_SIZE.width, BEFORE_BREAK_SIZE.height)
        .decorations(false)
        .shadow(true)
        .always_on_top(true)
        .visible_on_all_workspaces(true)
        .resizable(false)
        .minimizable(false)
        .maximizable(false)
        .focused(false)
        .transparent(true)
        .effects(material(Effect::Popover, Some(PANEL_RADIUS)))
        .visible(false);
    if let Some(m) = app.primary_monitor()? {
        // Builder positions are logical.
        let pos = top_right(app, BEFORE_BREAK_SIZE)?
            .unwrap_or_default()
            .to_logical::<f64>(m.scale_factor());
        b = b.position(pos.x, pos.y);
    }
    let w = b.build()?;
    macos::style_panel(&w)?;
    notify_destroyed(&w);
    macos::show_without_focus(&w)
}

/// Card-sized window with native chrome (traffic lights over the page, hidden title),
/// top-right of the primary work area under the tray icon; closes on blur, close button, Cmd+W.
pub fn open_menu_window(app: &AppHandle) -> tauri::Result<()> {
    open_menu_window_at(app, None)
}

/// `pane` (dev aid): `settings` or `stop-protection` opens the menu on that pane.
pub fn open_menu_window_at(app: &AppHandle, pane: Option<&str>) -> tauri::Result<()> {
    macos::activate_app();
    if let Some(w) = app.get_webview_window(MENU) {
        w.show()?;
        return w.set_focus();
    }
    let r = match pane {
        Some(p) if p == "settings" || p == "stop-protection" => format!("menu?pane={p}"),
        _ => "menu".to_string(),
    };
    let b = WebviewWindowBuilder::new(app, MENU, route(&r))
        .title("Save My Eyes")
        .decorations(true)
        .resizable(false)
        .minimizable(false)
        .always_on_top(true)
        .inner_size(MENU_SIZE.width, MENU_SIZE.height)
        .transparent(true)
        .effects(material(Effect::Popover, None))
        .visible(false);
    #[cfg(target_os = "macos")]
    let b = b
        .title_bar_style(tauri::TitleBarStyle::Overlay)
        .hidden_title(true);
    let w = b.build()?;
    if let Some(pos) = top_right(app, MENU_SIZE)? {
        w.set_position(pos)?;
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

fn destroy_where(app: &AppHandle, pred: impl Fn(&str) -> bool) -> tauri::Result<()> {
    for (label, w) in app.webview_windows() {
        if pred(&label) {
            w.destroy()?;
        }
    }
    Ok(())
}

pub fn close_before_break_window(app: &AppHandle) -> tauri::Result<()> {
    destroy_where(app, |l| l == BEFORE_BREAK)
}

/// `before-break`, `break` and every `cover-N`; never `menu`.
pub fn close_break_windows(app: &AppHandle) -> tauri::Result<()> {
    destroy_where(app, |l| {
        l == BEFORE_BREAK || l == BREAK || l.starts_with(COVER_PREFIX)
    })
}

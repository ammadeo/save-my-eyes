//! macOS-only AppKit tweaks Tauri has no API for. Every function is a no-op elsewhere.

use tauri::{AppHandle, WebviewWindow};

/// Raise a cover window above the menu bar, the Dock and other apps' fullscreen Spaces.
///
/// Must be called on the main thread (`setup`, a tray/window event handler, or
/// `AppHandle::run_on_main_thread`).
pub fn elevate_cover_window(w: &WebviewWindow) -> tauri::Result<()> {
    #[cfg(target_os = "macos")]
    {
        use objc2_app_kit::{NSScreenSaverWindowLevel, NSWindow, NSWindowCollectionBehavior as B};
        let ptr = w.ns_window()?.cast::<NSWindow>();
        // SAFETY: Tauri hands out the live NSWindow backing `w`; callers are on the main thread.
        let ns: &NSWindow = unsafe { &*ptr };
        ns.setLevel(NSScreenSaverWindowLevel);
        ns.setCollectionBehavior(B::CanJoinAllSpaces | B::FullScreenAuxiliary | B::Stationary);
    }
    #[cfg(not(target_os = "macos"))]
    let _ = w;
    Ok(())
}

/// Run as a menu-bar-only agent: no Dock icon, no app menu. `LSUIElement` in
/// `src-tauri/Info.plist` covers bundled launches; this covers `cargo run`/`tauri dev`.
pub fn hide_from_dock(app: &AppHandle) {
    #[cfg(target_os = "macos")]
    if let Err(e) = app.set_activation_policy(tauri::ActivationPolicy::Accessory) {
        eprintln!("hide_from_dock: {e}");
    }
    #[cfg(not(target_os = "macos"))]
    let _ = app;
}

//! macOS-only AppKit tweaks Tauri has no API for. Every function is a no-op (or the
//! portable Tauri equivalent) elsewhere. All of them must run on the main thread.

use tauri::{AppHandle, WebviewWindow};

#[cfg(target_os = "macos")]
fn ns_window(w: &WebviewWindow) -> tauri::Result<&objc2_app_kit::NSWindow> {
    let ptr = w.ns_window()?.cast::<objc2_app_kit::NSWindow>();
    // SAFETY: Tauri hands out the live NSWindow backing `w`; callers are on the main thread
    // and only use the reference while `w` is alive.
    Ok(unsafe { &*ptr })
}

/// Raise a cover window above the menu bar, the Dock and other apps' fullscreen Spaces.
pub fn elevate_cover_window(w: &WebviewWindow) -> tauri::Result<()> {
    #[cfg(target_os = "macos")]
    {
        use objc2_app_kit::{NSScreenSaverWindowLevel, NSWindowCollectionBehavior as B};
        let ns = ns_window(w)?;
        ns.setLevel(NSScreenSaverWindowLevel);
        ns.setCollectionBehavior(B::CanJoinAllSpaces | B::FullScreenAuxiliary | B::Stationary);
    }
    #[cfg(not(target_os = "macos"))]
    let _ = w;
    Ok(())
}

/// Notification-banner look for the `before-break` card: rounded corners, system shadow,
/// shown on every Space including other apps' fullscreen Spaces (floating level comes from
/// `always_on_top`).
pub fn style_panel(w: &WebviewWindow) -> tauri::Result<()> {
    #[cfg(target_os = "macos")]
    {
        use objc2::msg_send;
        use objc2::runtime::AnyObject;
        use objc2_app_kit::{NSColor, NSWindowCollectionBehavior as B};
        let ns = ns_window(w)?;
        ns.setCollectionBehavior(B::CanJoinAllSpaces | B::FullScreenAuxiliary);
        // Round the content view's layer; the window itself must be non-opaque with a clear
        // background so the clipped corners are not filled. Not click-through: the card
        // still receives every click inside its bounds.
        ns.setOpaque(false);
        ns.setBackgroundColor(Some(&NSColor::clearColor()));
        if let Some(view) = ns.contentView() {
            view.setWantsLayer(true);
            // SAFETY: plain CALayer property setters on the view's own layer, main thread.
            unsafe {
                let layer: *mut AnyObject = msg_send![&*view, layer];
                if let Some(layer) = layer.as_ref() {
                    let _: () = msg_send![layer, setCornerRadius: 12.0f64];
                    let _: () = msg_send![layer, setMasksToBounds: true];
                }
            }
        }
        ns.invalidateShadow();
    }
    #[cfg(not(target_os = "macos"))]
    let _ = w;
    Ok(())
}

/// Order the window front without making it key, so it does not steal keyboard focus.
pub fn show_without_focus(w: &WebviewWindow) -> tauri::Result<()> {
    #[cfg(target_os = "macos")]
    {
        ns_window(w)?.orderFrontRegardless();
        Ok(())
    }
    #[cfg(not(target_os = "macos"))]
    w.show()
}

/// Make this (Accessory) app active so its new window becomes key and gets blur events.
pub fn activate_app() {
    #[cfg(target_os = "macos")]
    if let Some(mtm) = objc2::MainThreadMarker::new() {
        objc2_app_kit::NSApplication::sharedApplication(mtm).activate();
    } else {
        eprintln!("[macos] activate_app called off the main thread; ignored");
    }
}

/// Run as a menu-bar-only agent: no Dock icon. `LSUIElement` in `src-tauri/Info.plist`
/// covers bundled launches; this covers `cargo run`/`tauri dev`.
pub fn hide_from_dock(app: &AppHandle) {
    #[cfg(target_os = "macos")]
    if let Err(e) = app.set_activation_policy(tauri::ActivationPolicy::Accessory) {
        eprintln!("[macos] hide_from_dock: {e}");
    }
    #[cfg(not(target_os = "macos"))]
    let _ = app;
}

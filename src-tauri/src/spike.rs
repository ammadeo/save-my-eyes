//! Phase 0 spike (`SME_SPIKE=1`): timed window demo for screenshots. Delete in Phase 1.
//!
//! Synthetic input from outside the app is blocked by TCC on this Mac (no Accessibility
//! grant), so the native close button and Cmd+W are exercised from inside the process.

use tauri::{AppHandle, Manager};

use crate::{tray, windows};

type Step = fn(&AppHandle) -> tauri::Result<()>;

fn log_menu(app: &AppHandle) -> tauri::Result<()> {
    let w = app.get_webview_window(windows::MENU);
    let focused = w.as_ref().map(|w| w.is_focused()).transpose()?;
    eprintln!("[spike] menu exists={} focused={focused:?}", w.is_some());
    Ok(())
}

pub fn run(app: AppHandle) {
    let steps: [(u64, &'static str, Step); 13] = [
        (1, "tray left-click handler -> menu", |a| {
            tray::on_left_click(a);
            Ok(())
        }),
        (1, "check menu", log_menu),
        (3, "menu: NSWindow performClose (close-button action)", |a| {
            perform_close(a)
        }),
        (1, "check menu", log_menu),
        (1, "tray left-click handler -> menu again", |a| {
            tray::on_left_click(a);
            Ok(())
        }),
        (1, "menu: NSApp activate + makeKeyAndOrderFront", activate_menu),
        (1, "menu: NSApp sendEvent synthetic Cmd+W", send_cmd_w),
        (1, "check menu", log_menu),
        (3, "open covers", windows::open_cover_windows),
        (8, "close covers", windows::close_cover_windows),
        (5, "re-open covers", windows::open_cover_windows),
        (8, "close covers", windows::close_cover_windows),
        (1, "spike done", |_| Ok(())),
    ];
    std::thread::spawn(move || {
        for (delay, name, step) in steps {
            std::thread::sleep(std::time::Duration::from_secs(delay));
            eprintln!("[spike] {name}");
            let a = app.clone();
            let _ = app.run_on_main_thread(move || {
                if let Err(e) = step(&a) {
                    eprintln!("[spike] {name} failed: {e}");
                }
            });
        }
    });
}

#[cfg(target_os = "macos")]
fn menu_ns_window(app: &AppHandle) -> tauri::Result<Option<&'static objc2_app_kit::NSWindow>> {
    let Some(w) = app.get_webview_window(windows::MENU) else {
        return Ok(None);
    };
    // SAFETY: live window, main thread; only used within this step.
    Ok(Some(unsafe { &*w.ns_window()?.cast() }))
}

#[cfg(target_os = "macos")]
fn perform_close(app: &AppHandle) -> tauri::Result<()> {
    if let Some(ns) = menu_ns_window(app)? {
        ns.performClose(None);
    }
    Ok(())
}

/// Experiment: can a timer-driven (not user-initiated) Accessory app take key focus?
#[cfg(target_os = "macos")]
fn activate_menu(app: &AppHandle) -> tauri::Result<()> {
    let Some(ns) = menu_ns_window(app)? else {
        return Ok(());
    };
    let nsapp = objc2_app_kit::NSApplication::sharedApplication(
        objc2::MainThreadMarker::new().expect("main thread"),
    );
    eprintln!("[spike] before activate: app active={}", nsapp.isActive());
    nsapp.activate();
    ns.makeKeyAndOrderFront(None);
    Ok(())
}

#[cfg(target_os = "macos")]
fn send_cmd_w(app: &AppHandle) -> tauri::Result<()> {
    use objc2::MainThreadMarker;
    use objc2_app_kit::{NSApplication, NSEvent, NSEventModifierFlags, NSEventType};
    use objc2_foundation::{NSPoint, NSString};
    let Some(ns) = menu_ns_window(app)? else {
        return Ok(());
    };
    let mtm = MainThreadMarker::new().expect("main thread");
    let nsapp = NSApplication::sharedApplication(mtm);
    // Tauri's default app menu: list the Cmd+W / Cmd+Q key equivalents it registers.
    if let Some(main) = nsapp.mainMenu() {
        for top in main.itemArray() {
            let Some(sub) = top.submenu() else { continue };
            for item in sub.itemArray() {
                let key = item.keyEquivalent().to_string();
                if key == "w" || key == "q" {
                    eprintln!("[spike] mainMenu item {:?} = Cmd+{key}", item.title().to_string());
                }
            }
        }
    } else {
        eprintln!("[spike] no mainMenu");
    }
    eprintln!(
        "[spike] app active={} key window is menu={}",
        nsapp.isActive(),
        nsapp.keyWindow().is_some_and(|k| std::ptr::eq(&*k, ns))
    );
    let w = NSString::from_str("w");
    let ev = NSEvent::keyEventWithType_location_modifierFlags_timestamp_windowNumber_context_characters_charactersIgnoringModifiers_isARepeat_keyCode(
        NSEventType::KeyDown,
        NSPoint::new(0.0, 0.0),
        NSEventModifierFlags::Command,
        0.0,
        ns.windowNumber(),
        None,
        &w,
        &w,
        false,
        13, // kVK_ANSI_W
    );
    if let Some(ev) = ev {
        nsapp.sendEvent(&ev);
    }
    Ok(())
}

#[cfg(not(target_os = "macos"))]
fn perform_close(_: &AppHandle) -> tauri::Result<()> {
    Ok(())
}

#[cfg(not(target_os = "macos"))]
fn activate_menu(_: &AppHandle) -> tauri::Result<()> {
    Ok(())
}

#[cfg(not(target_os = "macos"))]
fn send_cmd_w(_: &AppHandle) -> tauri::Result<()> {
    Ok(())
}

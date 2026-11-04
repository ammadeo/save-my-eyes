mod macos;
mod spike;
mod tray;
mod windows;

use tauri::RunEvent;

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .setup(|app| {
            let handle = app.handle().clone();
            macos::hide_from_dock(&handle);
            tray::build_tray(&handle)?;
            if std::env::var_os("SME_SPIKE").is_some() {
                spike::run(handle);
            }
            Ok(())
        })
        .build(tauri::generate_context!())
        .expect("error while building tauri application")
        .run(|_app, event| {
            // Menu-bar agent: closing the last window must not quit the app.
            if let RunEvent::ExitRequested { api, code: None, .. } = event {
                api.prevent_exit();
            }
        });
}

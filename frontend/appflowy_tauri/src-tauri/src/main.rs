#![cfg_attr(
    all(not(debug_assertions), target_os = "windows"),
    windows_subsystem = "windows"
)]

mod event;
mod init;
mod request;

use event::*;
use flowy_core::FlowySDK;
use init::*;
use request::*;
use tauri::{Manager, State};

fn main() {
    let sdk = init_flowy_core();
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![invoke_request])
        .manage(sdk)
        .on_window_event(|_window_event| {})
        .on_menu_event(|_menu| {})
        .on_page_load(|window, _payload| {
            let app_handler = window.app_handle();
            // tauri::async_runtime::spawn(async move {});
            window.listen_global(AF_EVENT, move |event| {
                on_event(app_handler.clone(), event);
            });
        })
        .setup(|app| {
            let window = app.get_window("main").unwrap();
            #[cfg(debug_assertions)]
            window.open_devtools();
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}

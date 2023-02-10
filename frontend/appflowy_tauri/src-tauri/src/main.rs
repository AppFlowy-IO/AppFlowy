#![cfg_attr(
    all(not(debug_assertions), target_os = "windows"),
    windows_subsystem = "windows"
)]

mod init;
mod notification;
mod request;

use flowy_notification::register_notification_sender;
use init::*;
use notification::*;
use request::*;
use tauri::Manager;

fn main() {
    let flowy_core = init_flowy_core();
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![invoke_request])
        .manage(flowy_core)
        .on_window_event(|_window_event| {})
        .on_menu_event(|_menu| {})
        .on_page_load(|window, _payload| {
            let app_handler = window.app_handle();
            register_notification_sender(TSNotificationSender::new(app_handler.clone()));
            // tauri::async_runtime::spawn(async move {});
            window.listen_global(AF_EVENT, move |event| {
                on_event(app_handler.clone(), event);
            });
        })
        .setup(|app| {
            #[cfg(debug_assertions)]
            {
                let window = app.get_window("main").unwrap();
                window.open_devtools();
            }
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}

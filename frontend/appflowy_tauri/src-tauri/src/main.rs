#![cfg_attr(
  all(not(debug_assertions), target_os = "windows"),
  windows_subsystem = "windows"
)]

mod init;
mod notification;
mod request;

use flowy_notification::{register_notification_sender, unregister_all_notification_sender};
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
      // Make sure hot reload won't register the notification sender twice
      unregister_all_notification_sender();
      register_notification_sender(TSNotificationSender::new(app_handler.clone()));
      // tauri::async_runtime::spawn(async move {});
      window.listen_global(AF_EVENT, move |event| {
        on_event(app_handler.clone(), event);
      });
    })
    .setup(|_app| {
      let splashscreen_window = _app.get_window("splashscreen").unwrap();
      let window = _app.get_window("main").unwrap();

      // we perform the initialization code on a new task so the app doesn't freeze
      tauri::async_runtime::spawn(async move {
        // initialize your app here instead of sleeping :)
        println!("Initializing...");
        std::thread::sleep(std::time::Duration::from_secs(2));
        println!("Done initializing.");

        // After it's done, close the splashscreen and display the main window
        splashscreen_window.close().unwrap();
        window.show().unwrap();
      });
      Ok(())
    })
    .run(tauri::generate_context!())
    .expect("error while running tauri application");
}

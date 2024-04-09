#![cfg_attr(
  all(not(debug_assertions), target_os = "windows"),
  windows_subsystem = "windows"
)]

#[allow(dead_code)]
pub const DEEP_LINK_SCHEME: &str = "appflowy-flutter";
pub const OPEN_DEEP_LINK: &str = "open_deep_link";

mod init;
mod notification;
mod request;

use flowy_notification::{register_notification_sender, unregister_all_notification_sender};
use init::*;
use notification::*;
use request::*;
use tauri::Manager;
extern crate dotenv;

fn main() {
  tauri_plugin_deep_link::prepare(DEEP_LINK_SCHEME);

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
      let handle = _app.handle();

      // we perform the initialization code on a new task so the app doesn't freeze
      tauri::async_runtime::spawn(async move {
        // initialize your app here instead of sleeping :)
        std::thread::sleep(std::time::Duration::from_secs(2));

        // After it's done, close the splashscreen and display the main window
        splashscreen_window.close().unwrap();
        window.show().unwrap();
        // If you need macOS support this must be called in .setup() !
        // Otherwise this could be called right after prepare() but then you don't have access to tauri APIs
        // On macOS You still have to install a .app bundle you got from tauri build --debug for this to work!
        tauri_plugin_deep_link::register(
          DEEP_LINK_SCHEME,
          move |request| {
            dbg!(&request);
            handle.emit_all(OPEN_DEEP_LINK, request).unwrap();
          },
        )
        .unwrap(/* If listening to the scheme is optional for your app, you don't want to unwrap here. */);
      });

      Ok(())
    })
    .run(tauri::generate_context!())
    .expect("error while running tauri application");
}

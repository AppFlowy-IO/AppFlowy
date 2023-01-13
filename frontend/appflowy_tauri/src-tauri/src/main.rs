#![cfg_attr(
all(not(debug_assertions), target_os = "windows"),
windows_subsystem = "windows"
)]
use tauri::{Manager, Wry};

const AF_EVENT: &'static str = "af-event";
const AF_NOTIFICATION: &'static str = "af-notification";

#[derive(Clone, serde::Serialize)]
struct Payload {
    message: String,
}


// Learn more about Tauri commands at https://tauri.app/v1/guides/features/command
#[tauri::command]
fn greet(name: &str, app_handle: tauri::AppHandle<Wry>) -> String {
    app_handle.emit_all(AF_NOTIFICATION, Payload { message: "Payload from the backend".into() }).unwrap();
    format!("Hello, {}! You've been greeted from Rust!", name)

}

fn main() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![greet])
        .setup(|app| {
            app.listen_global(AF_EVENT, |event| {
                println!("{}: {:?}", AF_EVENT, event.payload());
            });

            let window = app.get_window("main").unwrap();
            #[cfg(debug_assertions)]
            window.open_devtools();
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}

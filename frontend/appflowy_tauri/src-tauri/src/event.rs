use serde::Serialize;
use tauri::{AppHandle, Event, Manager, Wry};

#[allow(dead_code)]
pub const AF_EVENT: &str = "af-event";
#[allow(dead_code)]
pub const AF_NOTIFICATION: &str = "af-notification";

#[tracing::instrument(level = "trace")]
pub fn on_event(app_handler: AppHandle<Wry>, event: Event) {}

#[allow(dead_code)]
pub fn send_notification<P: Serialize + Clone>(app_handler: AppHandle<Wry>, payload: P) {
    app_handler.emit_all(AF_NOTIFICATION, payload).unwrap();
}

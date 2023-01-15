use serde::Serialize;
use tauri::{AppHandle, Event, Manager, Wry};

pub const AF_EVENT: &'static str = "af-event";
pub const AF_NOTIFICATION: &'static str = "af-notification";

#[tracing::instrument(level = "trace")]
pub fn on_event(app_handler: AppHandle<Wry>, event: Event) {}

pub fn send_notification<P: Serialize + Clone>(app_handler: AppHandle<Wry>, payload: P) {
    app_handler.emit_all(AF_NOTIFICATION, payload).unwrap();
}

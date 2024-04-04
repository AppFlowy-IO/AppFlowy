use flowy_notification::entities::SubscribeObject;
use flowy_notification::NotificationSender;
use serde::Serialize;
use tauri::{AppHandle, Event, Manager, Wry};

#[allow(dead_code)]
pub const AF_EVENT: &str = "af-event";
pub const AF_NOTIFICATION: &str = "af-notification";

#[tracing::instrument(level = "trace")]
pub fn on_event(app_handler: AppHandle<Wry>, event: Event) {}

#[allow(dead_code)]
pub fn send_notification<P: Serialize + Clone>(app_handler: AppHandle<Wry>, payload: P) {
  app_handler.emit_all(AF_NOTIFICATION, payload).unwrap();
}

pub struct TSNotificationSender {
  handler: AppHandle<Wry>,
}

impl TSNotificationSender {
  pub fn new(handler: AppHandle<Wry>) -> Self {
    Self { handler }
  }
}

impl NotificationSender for TSNotificationSender {
  fn send_subject(&self, subject: SubscribeObject) -> Result<(), String> {
    self
      .handler
      .emit_all(AF_NOTIFICATION, subject)
      .map_err(|e| format!("{:?}", e))
  }
}

use flowy_notification::entities::SubscribeObject;
use flowy_notification::NotificationSender;

pub const AF_NOTIFICATION: &str = "af-notification";

pub struct TSNotificationSender {}

impl TSNotificationSender {
  pub(crate) fn new() -> Self {
    TSNotificationSender {}
  }
}

impl NotificationSender for TSNotificationSender {
  fn send_subject(&self, _subject: SubscribeObject) -> Result<(), String> {
    // on_event(AF_NOTIFICATION, serde_wasm_bindgen::to_value(&subject).unwrap_or(JsValue::UNDEFINED));
    Ok(())
  }
}

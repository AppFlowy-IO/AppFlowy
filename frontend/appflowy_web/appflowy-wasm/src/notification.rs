// use flowy_notification::entities::SubscribeObject;
// use flowy_notification::NotificationSender;
// use wasm_bindgen::JsValue;
// use crate::on_event;
//
// pub const AF_NOTIFICATION: &str = "af-notification";
//
// pub struct TSNotificationSender {}
//
// impl NotificationSender for TSNotificationSender {
//   fn send_subject(&self, subject: SubscribeObject) -> Result<(), String> {
//     on_event(AF_NOTIFICATION, serde_wasm_bindgen::to_value(&subject).unwrap_or(JsValue::UNDEFINED));
//     Ok(())
//   }
// }
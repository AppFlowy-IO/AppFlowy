
extern crate wasm_bindgen;

use js_sys::Error;
use flowy_notification::{register_notification_sender, unregister_all_notification_sender};
use wasm_bindgen::prelude::*;
use crate::notification::TSNotificationSender;

pub mod request;
pub mod notification;

#[wasm_bindgen]
extern {
    #[wasm_bindgen(js_namespace = console)]
    fn log(s: &str);

    #[wasm_bindgen(js_namespace = window)]
    fn onFlowyNotify(event_name: &str, payload: JsValue);
}

#[wasm_bindgen]
pub async fn invoke_request(ty: String, payload: Vec<u8>) -> Result<JsValue, Error> {
    let response = request::invoke_request(ty, payload).await;
    response.map(|response| serde_wasm_bindgen::to_value(&response).unwrap_or(JsValue::UNDEFINED))
}

#[wasm_bindgen]
pub fn register_listener() {
    unregister_all_notification_sender();
    register_notification_sender(TSNotificationSender::new());
}

pub fn on_event(event_name: &str, args: JsValue) {
    onFlowyNotify(event_name, args);
}
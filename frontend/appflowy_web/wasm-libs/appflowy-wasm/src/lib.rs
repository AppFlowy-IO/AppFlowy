use crate::notification::TSNotificationSender;
use flowy_notification::{register_notification_sender, unregister_all_notification_sender};

mod core;
mod integrate;
pub mod notification;
pub mod request;

use crate::request::{MutexDispatcher, WasmRequest};
use lazy_static::lazy_static;
use lib_dispatch::prelude::AFPluginDispatcher;
use lib_dispatch::runtime::AFPluginRuntime;
use std::sync::Arc;
use tracing::trace;
use wasm_bindgen::prelude::wasm_bindgen;
use wasm_bindgen::JsValue;

lazy_static! {
  pub(crate) static ref DISPATCHER: MutexDispatcher = MutexDispatcher::new();
}

#[wasm_bindgen]
pub fn init_sdk(_data: String) -> i64 {
  let runtime = Arc::new(AFPluginRuntime::new().unwrap());
  *DISPATCHER.0.lock() = Some(Arc::new(AFPluginDispatcher::new(runtime, vec![])));
  0
}

#[wasm_bindgen]
pub fn init_tracing() {
  tracing_wasm::set_as_global_default();
}

#[wasm_bindgen]
pub fn async_event(name: String, payload: Vec<u8>) {
  trace!("[WASM]: receives event: {}", name);

  let dispatcher = DISPATCHER.0.lock().as_ref().unwrap().clone();
  AFPluginDispatcher::boxed_async_send_with_callback(
    dispatcher,
    WasmRequest::new(name, payload),
    |_| Box::pin(async {}),
  );
}

#[wasm_bindgen]
extern "C" {
  #[wasm_bindgen(js_namespace = console)]
  pub fn log(s: &str);
  #[wasm_bindgen(js_namespace = window)]
  fn onFlowyNotify(event_name: &str, payload: JsValue);
}

#[wasm_bindgen]
pub fn register_listener() {
  unregister_all_notification_sender();
  register_notification_sender(TSNotificationSender::new());
}

pub fn on_event(event_name: &str, args: JsValue) {
  onFlowyNotify(event_name, args);
}

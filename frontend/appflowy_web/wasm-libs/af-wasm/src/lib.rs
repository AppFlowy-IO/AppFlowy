use crate::notification::TSNotificationSender;
use flowy_notification::{register_notification_sender, unregister_all_notification_sender};
use std::cell::RefCell;

pub mod core;
mod integrate;
pub mod notification;
pub mod request;

use crate::core::AppFlowyWASMCore;
use crate::request::WasmRequest;
use lazy_static::lazy_static;
use lib_dispatch::prelude::{af_spawn, AFPluginDispatcher};

use std::sync::Arc;
use tracing::{error, info, trace};
use wasm_bindgen::prelude::wasm_bindgen;
use wasm_bindgen::JsValue;

lazy_static! {
  static ref APPFLOWY_CORE: RefCellAppFlowyCore = RefCellAppFlowyCore::new();
}

#[wasm_bindgen]
pub fn init_sdk(_data: String) -> i64 {
  af_spawn(async {
    if let Ok(core) = AppFlowyWASMCore::new("device_id").await {
      info!("AppFlowyWASMCore initialized");
      *APPFLOWY_CORE.0.borrow_mut() = Some(core);
    } else {
      error!("Failed to initialize AppFlowyWASMCore")
    }
  });
  0
}

#[wasm_bindgen]
pub fn init_tracing() {
  tracing_wasm::set_as_global_default();
}

#[wasm_bindgen]
pub fn async_event(name: String, payload: Vec<u8>) {
  trace!("[WASM]: receives event: {}", name);
  if let Some(dispatcher) = APPFLOWY_CORE.dispatcher() {
    AFPluginDispatcher::boxed_async_send_with_callback(
      dispatcher,
      WasmRequest::new(name, payload),
      |_| Box::pin(async {}),
    );
  } else {
    error!(
      "Dispatcher is not initialized, failed to send event: {}",
      name
    );
  }
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

struct RefCellAppFlowyCore(RefCell<Option<AppFlowyWASMCore>>);

/// safety:
/// In a WebAssembly, implement the Sync for RefCellAppFlowyCore is safety
/// since WASM currently operates in a single-threaded environment.
unsafe impl Sync for RefCellAppFlowyCore {}

impl RefCellAppFlowyCore {
  fn new() -> Self {
    Self(RefCell::new(None))
  }

  fn dispatcher(&self) -> Option<Arc<AFPluginDispatcher>> {
    self
      .0
      .borrow()
      .as_ref()
      .map(|core| core.event_dispatcher.clone())
  }
}

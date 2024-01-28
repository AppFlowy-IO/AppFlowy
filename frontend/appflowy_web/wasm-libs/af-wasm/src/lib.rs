use crate::notification::TSNotificationSender;
use flowy_notification::{register_notification_sender, unregister_all_notification_sender};
use std::cell::RefCell;
use std::rc::Rc;

pub mod core;
mod integrate;
pub mod notification;
pub mod request;

use crate::core::AppFlowyWASMCore;
use crate::request::WasmRequest;
use lazy_static::lazy_static;
use lib_dispatch::prelude::AFPluginDispatcher;

use flowy_server_pub::af_cloud_config::AFCloudConfiguration;
use tracing::{error, trace};
use wasm_bindgen::prelude::wasm_bindgen;
use wasm_bindgen::JsValue;

lazy_static! {
  static ref APPFLOWY_CORE: RefCellAppFlowyCore = RefCellAppFlowyCore::new();
}

#[wasm_bindgen]
pub fn init_sdk(_data: String) -> i64 {
  #[cfg(feature = "localhost_dev")]
  let config = AFCloudConfiguration {
    base_url: "http://localhost".to_string(),
    ws_base_url: "ws://localhost/ws".to_string(),
    gotrue_url: "http://localhost/gotrue".to_string(),
  };

  #[cfg(not(feature = "localhost_dev"))]
  let config = AFCloudConfiguration {
    base_url: "https://beta.appflowy.cloud".to_string(),
    ws_base_url: "wss://beta.appflowy.cloud/ws".to_string(),
    gotrue_url: "https://beta.appflowy.cloud/gotrue".to_string(),
  };

  wasm_bindgen_futures::spawn_local(async {
    if let Ok(core) = AppFlowyWASMCore::new("device_id", config).await {
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
      dispatcher.as_ref(),
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

  fn dispatcher(&self) -> Option<Rc<AFPluginDispatcher>> {
    self
      .0
      .borrow()
      .as_ref()
      .map(|core| core.event_dispatcher.clone())
  }
}

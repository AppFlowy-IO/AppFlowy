use crate::notification::TSNotificationSender;
use flowy_notification::{register_notification_sender, unregister_all_notification_sender};
use std::cell::RefCell;
use std::rc::Rc;

pub mod core;
mod deps_resolve;
mod integrate;
pub mod notification;

use crate::core::AppFlowyWASMCore;
use lazy_static::lazy_static;
use lib_dispatch::prelude::{
  AFPluginDispatcher, AFPluginEventResponse, AFPluginRequest, StatusCode,
};

use flowy_server_pub::af_cloud_config::AFCloudConfiguration;
use tracing::{error, info};
use wasm_bindgen::prelude::wasm_bindgen;
use wasm_bindgen::JsValue;
use wasm_bindgen_futures::{future_to_promise, js_sys};

lazy_static! {
  static ref APPFLOWY_CORE: RefCellAppFlowyCore = RefCellAppFlowyCore::new();
}

#[cfg(feature = "wee_alloc")]
#[global_allocator]
static ALLOC: wee_alloc::WeeAlloc = wee_alloc::WeeAlloc::INIT;

#[wasm_bindgen]
extern "C" {
  #[wasm_bindgen(js_namespace = console)]
  pub fn log(s: &str);
  #[wasm_bindgen(js_namespace = window)]
  fn onFlowyNotify(event_name: &str, payload: JsValue);
}
#[wasm_bindgen]
pub fn init_tracing_log() {
  tracing_wasm::set_as_global_default();
}

#[wasm_bindgen]
pub fn init_wasm_core() -> js_sys::Promise {
  // It's disabled in release mode so it doesn't bloat up the file size.
  #[cfg(debug_assertions)]
  console_error_panic_hook::set_once();

  #[cfg(feature = "localhost_dev")]
  let config = AFCloudConfiguration {
    base_url: "http://localhost".to_string(),
    ws_base_url: "ws://localhost/ws/v1".to_string(),
    gotrue_url: "http://localhost/gotrue".to_string(),
  };

  #[cfg(not(feature = "localhost_dev"))]
  let config = AFCloudConfiguration {
    base_url: "https://beta.appflowy.cloud".to_string(),
    ws_base_url: "wss://beta.appflowy.cloud/ws/v1".to_string(),
    gotrue_url: "https://beta.appflowy.cloud/gotrue".to_string(),
  };

  let future = async move {
    if let Ok(core) = AppFlowyWASMCore::new("device_id", config).await {
      *APPFLOWY_CORE.0.borrow_mut() = Some(core);
      info!("🔥🔥🔥Initialized AppFlowyWASMCore");
    } else {
      error!("Failed to initialize AppFlowyWASMCore")
    }
    Ok(JsValue::from_str(""))
  };
  future_to_promise(future)
}

#[wasm_bindgen]
pub fn async_event(name: String, payload: Vec<u8>) -> js_sys::Promise {
  if let Some(dispatcher) = APPFLOWY_CORE.dispatcher() {
    let future = async move {
      let request = WasmRequest::new(name, payload);
      let event_resp =
        AFPluginDispatcher::boxed_async_send_with_callback(dispatcher.as_ref(), request, |_| {
          Box::pin(async {})
        })
        .await;

      let response = WasmResponse::from(event_resp);
      serde_wasm_bindgen::to_value(&response).map_err(error_response)
    };

    future_to_promise(future)
  } else {
    future_to_promise(async { Err(JsValue::from_str("Dispatcher is not initialized")) })
  }
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

fn error_response(error: serde_wasm_bindgen::Error) -> JsValue {
  error!("Error: {}", error);
  serde_wasm_bindgen::to_value(&WasmResponse::error(error.to_string())).unwrap()
}

pub struct WasmRequest {
  name: String,
  payload: Vec<u8>,
}

impl WasmRequest {
  pub fn new(name: String, payload: Vec<u8>) -> Self {
    Self { name, payload }
  }
}

impl From<WasmRequest> for AFPluginRequest {
  fn from(request: WasmRequest) -> Self {
    AFPluginRequest::new(request.name).payload(request.payload)
  }
}

#[derive(serde::Serialize)]
pub struct WasmResponse {
  pub code: i8,
  pub payload: Vec<u8>,
}
impl WasmResponse {
  pub fn error(msg: String) -> Self {
    Self {
      code: StatusCode::Err as i8,
      payload: msg.into_bytes(),
    }
  }
}

impl From<AFPluginEventResponse> for WasmResponse {
  fn from(response: AFPluginEventResponse) -> Self {
    Self {
      code: response.status_code as i8,
      payload: response.payload.to_vec(),
    }
  }
}

use lazy_static::lazy_static;
use lib_dispatch::prelude::{AFPluginDispatcher, AFPluginRequest};
use lib_dispatch::runtime::AFPluginRuntime;
use parking_lot::Mutex;
use std::sync::Arc;
use tracing::trace;
use wasm_bindgen::prelude::wasm_bindgen;

lazy_static! {
  static ref DISPATCHER: MutexDispatcher = MutexDispatcher::new();
}

#[no_mangle]
#[wasm_bindgen]
pub fn init_sdk(data: String) -> i64 {
  let runtime = Arc::new(AFPluginRuntime::new().unwrap());
  *DISPATCHER.0.lock() = Some(Arc::new(AFPluginDispatcher::new(runtime, vec![])));
  0
}

#[wasm_bindgen]
pub fn init_tracing() {
  tracing_wasm::set_as_global_default();
}

struct MutexDispatcher(Arc<Mutex<Option<Arc<AFPluginDispatcher>>>>);

impl MutexDispatcher {
  fn new() -> Self {
    Self(Arc::new(Mutex::new(None)))
  }
}

unsafe impl Sync for MutexDispatcher {}
unsafe impl Send for MutexDispatcher {}

#[wasm_bindgen]
pub fn async_event(name: String, payload: Vec<u8>) {
  trace!("[WASM]: receives event: {}", name);

  let dispatcher = DISPATCHER.0.lock().as_ref().unwrap().clone();
  AFPluginDispatcher::boxed_async_send_with_callback(
    dispatcher,
    WasmEvent { name, payload },
    |_| Box::pin(async {}),
  );
}

#[wasm_bindgen]
extern "C" {
  #[wasm_bindgen(js_namespace = console)]
  pub fn log(s: &str);
}

#[wasm_bindgen]
pub struct WasmEvent {
  name: String,
  payload: Vec<u8>,
}

#[wasm_bindgen]
impl WasmEvent {
  pub fn name(&self) -> String {
    self.name.clone()
  }

  // Setter for the name
  #[wasm_bindgen(setter)]
  pub fn set_name(&mut self, name: String) {
    self.name = name;
  }

  // Getter for payload that returns a pointer to the data
  pub fn get_payload_ptr(&self) -> *const u8 {
    self.payload.as_ptr()
  }

  // Getter for the length of the payload
  pub fn get_payload_len(&self) -> usize {
    self.payload.len()
  }

  // Setter or method to update payload
  pub fn set_payload(&mut self, payload: &[u8]) {
    self.payload = payload.to_vec();
  }
}

impl From<WasmEvent> for AFPluginRequest {
  fn from(request: WasmEvent) -> Self {
    AFPluginRequest::new(request.name).payload(request.payload)
  }
}

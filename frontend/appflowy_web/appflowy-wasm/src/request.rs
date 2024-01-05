use lazy_static::lazy_static;
use lib_dispatch::prelude::{AFPluginDispatcher, AFPluginRequest};
use lib_dispatch::runtime::AFPluginRuntime;
use parking_lot::Mutex;
use std::sync::Arc;
use tracing::trace;
use wasm_bindgen::prelude::wasm_bindgen;

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
        WasmRequest { name, payload },
        |_| Box::pin(async {}),
    );
}

#[wasm_bindgen]
pub struct WasmRequest {
    name: String,
    payload: Vec<u8>,
}

impl From<WasmRequest> for AFPluginRequest {
    fn from(request: WasmRequest) -> Self {
        AFPluginRequest::new(request.name).payload(request.payload)
    }
}

#[wasm_bindgen]
impl WasmRequest {
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

impl From<WasmRequest> for AFPluginRequest {
    fn from(request: WasmEvent) -> Self {
        AFPluginRequest::new(request.name).payload(request.payload)
    }
}

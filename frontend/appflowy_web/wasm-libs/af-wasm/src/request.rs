use lib_dispatch::prelude::{AFPluginRequest};

use wasm_bindgen::prelude::wasm_bindgen;

#[wasm_bindgen]
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

use crate::util::tester::WASMEventTester;
use wasm_bindgen_test::wasm_bindgen_test;

#[wasm_bindgen_test]
async fn sign_up_event_test() {
  let tester = WASMEventTester::new().await;
}

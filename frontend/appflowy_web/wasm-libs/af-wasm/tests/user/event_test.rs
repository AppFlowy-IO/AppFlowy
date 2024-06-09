use crate::util::tester::{unique_email, WASMEventTester};
use wasm_bindgen_test::wasm_bindgen_test;

#[wasm_bindgen_test]
async fn sign_up_event_test() {
  let tester = WASMEventTester::new().await;
  let email = unique_email();
  let user_profile = tester.sign_in_with_email(&email).await.unwrap();
  assert_eq!(user_profile.email, email);
}

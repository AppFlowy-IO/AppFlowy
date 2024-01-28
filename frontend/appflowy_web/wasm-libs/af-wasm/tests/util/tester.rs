use af_wasm::core::AppFlowyWASMCore;
use flowy_error::FlowyResult;
use wasm_bindgen_test::console_log;

pub struct WASMEventTester {
  core: AppFlowyWASMCore,
}

impl WASMEventTester {
  pub async fn new() -> Self {
    // let (tx, mut rx) = tokio::sync::mpsc::channel(1);
    // wasm_bindgen_futures::spawn_local(async move {
    // match AppFlowyWASMCore::new("device_id").await {
    //   Ok(core) => {
    //     web_sys::console::log_1(&"init appflowy core success".into());
    //     tx.send(core).await.unwrap();
    //   },
    //   Err(err) => {
    //     console_log!("Error: {:?}", err)
    //   },
    // }
    // });
    let core = AppFlowyWASMCore::new("device_id").await.unwrap();
    Self { core }
  }
}

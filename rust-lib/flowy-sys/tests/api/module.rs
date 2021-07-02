use crate::helper::*;
use flowy_sys::prelude::*;

pub async fn hello() -> String { "say hello".to_string() }

#[tokio::test]
async fn test_init() {
    setup_env();
    let event = "1";
    init_system(|| vec![Module::new().event(event, hello)]);

    let request = DispatchRequest::new(1, event);
    let resp = async_send(request).await.unwrap();
    log::info!("sync resp: {:?}", resp);
}

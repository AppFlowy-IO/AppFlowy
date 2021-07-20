use crate::helper::*;
use flowy_dispatch::prelude::*;

pub async fn hello() -> String { "say hello".to_string() }

#[tokio::test]
async fn test_init() {
    setup_env();
    let event = "1";
    init_dispatch(|| vec![Module::new().event(event, hello)]);

    let request = ModuleRequest::new(event);
    let _ = EventDispatch::async_send_with_callback(request, |resp| {
        Box::pin(async move {
            dbg!(&resp);
        })
    })
    .await;
}

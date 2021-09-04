use crate::helper::*;
use flowy_dispatch::prelude::*;
use std::sync::Arc;

pub async fn hello() -> String { "say hello".to_string() }

#[tokio::test]
async fn test() {
    setup_env();
    let event = "1";
    let dispatch = Arc::new(init_dispatch(|| vec![Module::new().event(event, hello)]));
    let request = ModuleRequest::new(event);
    let _ = EventDispatch::async_send_with_callback(dispatch.clone(), request, |resp| {
        Box::pin(async move {
            dbg!(&resp);
        })
    })
    .await;

    std::mem::forget(dispatch);
}

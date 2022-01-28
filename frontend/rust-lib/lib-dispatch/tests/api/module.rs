use lib_dispatch::{prelude::*, util::tokio_default_runtime};
use std::sync::Arc;

pub async fn hello() -> String {
    "say hello".to_string()
}

#[tokio::test]
async fn test() {
    env_logger::init();

    let event = "1";
    let runtime = tokio_default_runtime().unwrap();
    let dispatch = Arc::new(EventDispatcher::construct(runtime, || {
        vec![Module::new().event(event, hello)]
    }));
    let request = ModuleRequest::new(event);
    let _ = EventDispatcher::async_send_with_callback(dispatch.clone(), request, |resp| {
        Box::pin(async move {
            dbg!(&resp);
        })
    })
    .await;

    std::mem::forget(dispatch);
}

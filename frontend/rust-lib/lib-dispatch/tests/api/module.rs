use lib_dispatch::prelude::*;
use lib_dispatch::runtime::tokio_default_runtime;
use std::sync::Arc;

pub async fn hello() -> String {
    "say hello".to_string()
}

#[tokio::test]
async fn test() {
    env_logger::init();

    let event = "1";
    let runtime = tokio_default_runtime().unwrap();
    let dispatch = Arc::new(AFPluginDispatcher::construct(runtime, || {
        vec![AFPlugin::new().event(event, hello)]
    }));
    let request = AFPluginRequest::new(event);
    let _ = AFPluginDispatcher::async_send_with_callback(dispatch.clone(), request, |resp| {
        Box::pin(async move {
            dbg!(&resp);
        })
    })
    .await;

    std::mem::forget(dispatch);
}

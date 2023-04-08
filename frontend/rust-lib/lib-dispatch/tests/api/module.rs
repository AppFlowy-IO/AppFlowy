use lib_dispatch::prelude::*;
use lib_dispatch::runtime::tokio_default_runtime;
use std::sync::Arc;
use tokio::runtime::Handle;

pub async fn hello() -> String {
  "say hello".to_string()
}

#[tokio::test]
async fn test() {
  let event = "1";
  tokio_default_runtime().unwrap();
  let dispatch = Arc::new(AFPluginDispatcher::construct(Handle::current(), || {
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

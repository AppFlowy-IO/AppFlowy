use lib_dispatch::prelude::*;
use lib_dispatch::runtime::AFPluginRuntime;
use std::sync::Arc;
use tokio::task::LocalSet;

pub async fn hello() -> String {
  "say hello".to_string()
}

#[tokio::test]
async fn test() {
  let event = "1";
  let runtime = Arc::new(AFPluginRuntime::new().unwrap());
  let dispatch = Arc::new(AFPluginDispatcher::new(
    runtime,
    vec![AFPlugin::new().event(event, hello)],
  ));
  let request = AFPluginRequest::new(event);
  let _ = AFPluginDispatcher::async_send_with_callback(
    dispatch.as_ref(),
    request,
    |resp| {
      Box::pin(async move {
        dbg!(&resp);
      })
    },
    &LocalSet::new(),
  )
  .await;

  std::mem::forget(dispatch);
}

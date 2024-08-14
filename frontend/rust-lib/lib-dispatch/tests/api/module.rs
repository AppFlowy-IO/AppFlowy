use std::rc::Rc;

use lib_dispatch::prelude::*;
use lib_dispatch::runtime::AFPluginRuntime;

pub async fn hello() -> String {
  "say hello".to_string()
}

#[tokio::test]
async fn test() {
  let event = "1";
  let runtime = Rc::new(AFPluginRuntime::new().unwrap());
  let dispatch = Rc::new(AFPluginDispatcher::new(
    runtime,
    vec![AFPlugin::new().event(event, hello)],
  ));
  let request = AFPluginRequest::new(event);
  let _ = AFPluginDispatcher::async_send_with_callback(dispatch.as_ref(), request, |resp| {
    Box::pin(async move {
      dbg!(&resp);
    })
  })
  .await;

  std::mem::forget(dispatch);
}

use js_sys::Error;
use serde::{Serialize, Deserialize};
// use lib_dispatch::prelude::*;
use tracing::{error, trace};


#[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize)]
pub enum StatusCode {
  Ok = 0,
  Err = 1,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct Response {
  code: StatusCode,
  payload: Vec<u8>,
}

pub async fn invoke_request(ty: String, payload: Vec<u8>) -> Result<Response, Error> {

  // let request: AFPluginRequest = AFPluginRequest::new(ty).payload(payload);

  // let dispatcher = match APPFLOWY_CORE.dispatcher() {
  //   None => {
  //     error!("sdk not init yet.");
  //     return Err(Error::default());
  //   },
  //   Some(dispatcher) => dispatcher,
  // };
  //
  // let response = AFPluginDispatcher::async_send(dispatcher, request).await;
  // Ok(Response {
  //   code: response.status_code,
  //   payload: response.payload.to_vec(),
  // })
  Ok(Response {
      code: StatusCode::Ok,
      payload: vec![],
  })
}
use js_sys::Error;
use serde::{Serialize, Deserialize};
// use lib_dispatch::prelude::*;
use tracing::{error, trace};
use wasm_bindgen::JsValue;
use crate::{on_event};


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

    let payload = serde_json::json!({
        "ty": ty,
        "payload": payload,
    });
    on_event("af-notification", serde_wasm_bindgen::to_value(&payload).unwrap_or(JsValue::UNDEFINED));
  Ok(Response {
      code: StatusCode::Ok,
      payload: vec![],
  })
}
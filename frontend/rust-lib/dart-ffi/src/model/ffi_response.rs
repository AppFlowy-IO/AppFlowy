use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use lib_dispatch::prelude::{AFPluginEventResponse, Payload, StatusCode};

#[derive(ProtoBuf_Enum, Clone, Copy, Default)]
pub enum FFIStatusCode {
  #[default]
  Ok = 0,
  Err = 1,
  Internal = 2,
}

#[derive(ProtoBuf, Default)]
pub struct FFIResponse {
  #[pb(index = 1)]
  payload: Vec<u8>,

  #[pb(index = 2)]
  code: FFIStatusCode,
}

impl std::convert::From<AFPluginEventResponse> for FFIResponse {
  fn from(resp: AFPluginEventResponse) -> Self {
    let payload = match resp.payload {
      Payload::Bytes(bytes) => bytes.to_vec(),
      Payload::None => vec![],
    };

    let code = match resp.status_code {
      StatusCode::Ok => FFIStatusCode::Ok,
      StatusCode::Err => FFIStatusCode::Err,
    };

    // let msg = match resp.error {
    //     None => "".to_owned(),
    //     Some(e) => format!("{:?}", e),
    // };

    FFIResponse { payload, code }
  }
}

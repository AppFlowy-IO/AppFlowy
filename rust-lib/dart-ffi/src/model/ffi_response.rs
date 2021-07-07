use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_sys::prelude::{EventResponse, Payload, StatusCode};

#[derive(ProtoBuf_Enum, Clone, Copy)]
pub enum FFIStatusCode {
    Unknown = 0,
    Ok      = 1,
    Err     = 2,
}

impl std::default::Default for FFIStatusCode {
    fn default() -> FFIStatusCode { FFIStatusCode::Unknown }
}

#[derive(ProtoBuf, Default)]
pub struct FFIResponse {
    #[pb(index = 1)]
    payload: Vec<u8>,

    #[pb(index = 2)]
    error: String,

    #[pb(index = 3)]
    code: FFIStatusCode,
}

impl std::convert::From<EventResponse> for FFIResponse {
    fn from(resp: EventResponse) -> Self {
        let payload = match resp.payload {
            Payload::Bytes(bytes) => bytes,
            Payload::None => vec![],
        };

        let error = match resp.error {
            Some(e) => format!("{}", e),
            None => "".to_owned(),
        };

        let code = match resp.status_code {
            StatusCode::Ok => FFIStatusCode::Ok,
            StatusCode::Err => FFIStatusCode::Err,
        };

        FFIResponse {
            payload,
            error,
            code,
        }
    }
}

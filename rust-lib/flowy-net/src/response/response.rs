use serde::Serialize;

use serde_repr::*;

#[derive(Serialize_repr, Deserialize_repr, PartialEq, Debug)]
#[repr(u16)]
pub enum ServerCode {
    Success          = 0,
    InvalidToken     = 1,
    InternalError    = 2,
    Unauthorized     = 3,
    PayloadOverflow  = 4,
    PayloadSerdeFail = 5,
}

#[derive(Debug, Serialize)]
pub struct FlowyResponse<T> {
    pub msg: String,
    pub data: Option<T>,
    pub code: ServerCode,
}

impl<T: Serialize> FlowyResponse<T> {
    pub fn new(data: Option<T>, msg: &str, code: ServerCode) -> Self {
        FlowyResponse {
            msg: msg.to_owned(),
            data,
            code,
        }
    }

    pub fn from_data(data: T, msg: &str, code: ServerCode) -> Self {
        Self::new(Some(data), msg, code)
    }
}

impl FlowyResponse<String> {
    pub fn success() -> Self { Self::from_msg("", ServerCode::Success) }

    pub fn from_msg(msg: &str, code: ServerCode) -> Self {
        Self::new(Some("".to_owned()), msg, code)
    }
}

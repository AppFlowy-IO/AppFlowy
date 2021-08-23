use bytes::Bytes;
use serde::{Deserialize, Serialize, __private::Formatter};
use serde_repr::*;
use std::{fmt, fmt::Debug};

use crate::response::FlowyResponse;

#[derive(thiserror::Error, Debug, Serialize, Deserialize, Clone)]
pub struct ServerError {
    pub code: Code,
    pub msg: String,
}

macro_rules! static_error {
    ($name:ident, $status:expr) => {
        #[allow(non_snake_case, missing_docs)]
        pub fn $name<T: Debug>(error: T) -> ServerError {
            let msg = format!("{:?}", error);
            ServerError { code: $status, msg }
        }
    };
}

impl ServerError {
    static_error!(internal, Code::InternalError);
    static_error!(http, Code::HttpError);
    static_error!(payload_none, Code::PayloadUnexpectedNone);
}

impl std::fmt::Display for ServerError {
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
        let msg = format!("{:?}:{}", self.code, self.msg);
        f.write_str(&msg)
    }
}

impl std::convert::From<&ServerError> for FlowyResponse {
    fn from(error: &ServerError) -> Self {
        FlowyResponse {
            data: Bytes::from(vec![]),
            error: Some(error.clone()),
        }
    }
}

#[derive(Serialize_repr, Deserialize_repr, PartialEq, Debug, Clone)]
#[repr(u16)]
pub enum Code {
    InvalidToken       = 1,
    Unauthorized       = 3,
    PayloadOverflow    = 4,
    PayloadSerdeFail   = 5,
    PayloadUnexpectedNone = 6,

    ProtobufError      = 10,
    SerdeError         = 11,

    EmailAlreadyExists = 50,

    ConnectRefused     = 100,
    ConnectTimeout     = 101,
    ConnectClose       = 102,
    ConnectCancel      = 103,

    SqlError           = 200,

    HttpError          = 300,

    InternalError      = 1000,
}

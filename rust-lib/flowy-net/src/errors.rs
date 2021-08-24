use bytes::Bytes;
use serde::{Deserialize, Serialize, __private::Formatter};
use serde_repr::*;
use std::{fmt, fmt::Debug};

use crate::response::FlowyResponse;
use uuid::Error;

#[derive(thiserror::Error, Debug, Serialize, Deserialize, Clone)]
pub struct ServerError {
    pub code: ErrorCode,
    pub msg: String,
    pub kind: Kind,
}

macro_rules! static_error {
    ($name:ident, $status:expr) => {
        #[allow(non_snake_case, missing_docs)]
        pub fn $name() -> ServerError {
            ServerError {
                code: $status,
                msg: format!("{}", $status),
                kind: Kind::Other,
            }
        }
    };
}

impl ServerError {
    static_error!(internal, ErrorCode::InternalError);
    static_error!(http, ErrorCode::HttpError);
    static_error!(payload_none, ErrorCode::PayloadUnexpectedNone);
    static_error!(unauthorized, ErrorCode::Unauthorized);
    static_error!(password_not_match, ErrorCode::PasswordNotMatch);
    static_error!(params_invalid, ErrorCode::ParamsInvalid);
    static_error!(connect_timeout, ErrorCode::ConnectTimeout);
    static_error!(connect_close, ErrorCode::ConnectClose);
    static_error!(connect_cancel, ErrorCode::ConnectCancel);
    static_error!(connect_refused, ErrorCode::ConnectRefused);

    pub fn new(msg: String, code: ErrorCode, kind: Kind) -> Self { Self { code, msg, kind } }

    pub fn kind(mut self, kind: Kind) -> Self {
        self.kind = kind;
        self
    }

    pub fn context<T: Debug>(mut self, error: T) -> Self {
        self.msg = format!("{:?}", error);
        self
    }
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

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum Kind {
    User,
    Other,
}

#[derive(Serialize_repr, Deserialize_repr, PartialEq, Debug, Clone, derive_more::Display)]
#[repr(u16)]
pub enum ErrorCode {
    #[display(fmt = "Token is invalid")]
    InvalidToken       = 1,
    #[display(fmt = "Unauthorized")]
    Unauthorized       = 2,
    #[display(fmt = "Payload too large")]
    PayloadOverflow    = 3,
    #[display(fmt = "Payload deserialize failed")]
    PayloadSerdeFail   = 4,
    #[display(fmt = "Unexpected empty payload")]
    PayloadUnexpectedNone = 5,
    #[display(fmt = "Params is invalid")]
    ParamsInvalid      = 6,

    #[display(fmt = "Protobuf serde error")]
    ProtobufError      = 10,
    #[display(fmt = "Json serde Error")]
    SerdeError         = 11,

    #[display(fmt = "Email address already exists")]
    EmailAlreadyExists = 50,

    #[display(fmt = "Username and password do not match")]
    PasswordNotMatch   = 51,

    #[display(fmt = "Connect refused")]
    ConnectRefused     = 100,

    #[display(fmt = "Connection timeout")]
    ConnectTimeout     = 101,
    #[display(fmt = "Connection closed")]
    ConnectClose       = 102,
    #[display(fmt = "Connection canceled")]
    ConnectCancel      = 103,

    #[display(fmt = "Sql error")]
    SqlError           = 200,

    #[display(fmt = "Http request error")]
    HttpError          = 300,

    #[display(fmt = "Internal error")]
    InternalError      = 1000,
}

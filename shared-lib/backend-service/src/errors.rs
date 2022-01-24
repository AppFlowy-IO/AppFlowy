use crate::response::FlowyResponse;
use bytes::Bytes;
use serde::{Deserialize, Serialize, __private::Formatter};
use serde_repr::*;
use std::{fmt, fmt::Debug};

pub type Result<T> = std::result::Result<T, ServerError>;
use flowy_collaboration::errors::CollaborateError;
#[derive(thiserror::Error, Debug, Serialize, Deserialize, Clone)]
pub struct ServerError {
    pub code: ErrorCode,
    pub msg: String,
}

macro_rules! static_error {
    ($name:ident, $status:expr) => {
        #[allow(non_snake_case, missing_docs)]
        pub fn $name() -> ServerError {
            ServerError {
                code: $status,
                msg: format!("{}", $status),
            }
        }
    };
}

impl ServerError {
    static_error!(internal, ErrorCode::InternalError);
    static_error!(http, ErrorCode::HttpError);
    static_error!(payload_none, ErrorCode::PayloadUnexpectedNone);
    static_error!(unauthorized, ErrorCode::UserUnauthorized);
    static_error!(password_not_match, ErrorCode::PasswordNotMatch);
    static_error!(params_invalid, ErrorCode::ParamsInvalid);
    static_error!(connect_timeout, ErrorCode::ConnectTimeout);
    static_error!(connect_close, ErrorCode::ConnectClose);
    static_error!(connect_cancel, ErrorCode::ConnectCancel);
    static_error!(connect_refused, ErrorCode::ConnectRefused);
    static_error!(record_not_found, ErrorCode::RecordNotFound);

    pub fn new(msg: String, code: ErrorCode) -> Self { Self { code, msg } }

    pub fn context<T: Debug>(mut self, error: T) -> Self {
        self.msg = format!("{:?}", error);
        self
    }

    pub fn is_record_not_found(&self) -> bool { self.code == ErrorCode::RecordNotFound }

    pub fn is_unauthorized(&self) -> bool { self.code == ErrorCode::UserUnauthorized }

    pub fn to_collaborate_error(&self) -> CollaborateError {
        if self.is_record_not_found() {
            CollaborateError::record_not_found()
        } else {
            CollaborateError::internal().context(self.msg.clone())
        }
    }
}

pub fn internal_error<T>(e: T) -> ServerError
where
    T: std::fmt::Debug,
{
    ServerError::internal().context(e)
}

pub fn invalid_params<T: Debug>(e: T) -> ServerError { ServerError::params_invalid().context(e) }

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

#[derive(Serialize_repr, Deserialize_repr, PartialEq, Debug, Clone, derive_more::Display)]
#[repr(u16)]
pub enum ErrorCode {
    #[display(fmt = "Unauthorized")]
    UserUnauthorized   = 1,
    #[display(fmt = "Payload too large")]
    PayloadOverflow    = 2,
    #[display(fmt = "Payload deserialize failed")]
    PayloadSerdeFail   = 3,
    #[display(fmt = "Unexpected empty payload")]
    PayloadUnexpectedNone = 4,
    #[display(fmt = "Params is invalid")]
    ParamsInvalid      = 5,

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
    #[display(fmt = "Record not found")]
    RecordNotFound     = 201,

    #[display(fmt = "Http request error")]
    HttpError          = 300,

    #[display(fmt = "Internal error")]
    InternalError      = 1000,
}

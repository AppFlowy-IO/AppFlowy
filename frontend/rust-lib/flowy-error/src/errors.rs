use crate::protobuf::ErrorCode as ProtoBufErrorCode;
use bytes::Bytes;
use derive_more::Display;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use lib_dispatch::prelude::{EventResponse, ResponseBuilder};
use protobuf::ProtobufEnum;
use std::{
    convert::{TryFrom, TryInto},
    fmt::Debug,
};

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct FlowyError {
    #[pb(index = 1)]
    pub code: i32,

    #[pb(index = 2)]
    pub msg: String,
}

macro_rules! static_any_error {
    ($name:ident, $code:expr) => {
        #[allow(non_snake_case, missing_docs)]
        pub fn $name() -> FlowyError { $code.into() }
    };
}

impl FlowyError {
    pub fn new(code: ErrorCode, msg: &str) -> Self {
        Self {
            code: code.value(),
            msg: msg.to_owned(),
        }
    }
    pub fn context<T: Debug>(mut self, error: T) -> Self {
        self.msg = format!("{:?}", error);
        self
    }

    static_any_error!(internal, ErrorCode::Internal);
}

impl std::convert::From<ErrorCode> for FlowyError {
    fn from(code: ErrorCode) -> Self {
        FlowyError {
            code: code.value(),
            msg: format!("{}", code),
        }
    }
}

#[derive(Debug, Clone, ProtoBuf_Enum, Display, PartialEq, Eq)]
pub enum ErrorCode {
    #[display(fmt = "Internal error")]
    Internal = 0,
}

impl ErrorCode {
    pub fn value(&self) -> i32 {
        let code: ProtoBufErrorCode = self.clone().try_into().unwrap();
        code.value()
    }

    pub fn from_i32(value: i32) -> Self {
        match ProtoBufErrorCode::from_i32(value) {
            None => ErrorCode::Internal,
            Some(code) => ErrorCode::try_from(&code).unwrap(),
        }
    }
}

pub fn internal_error<T>(e: T) -> FlowyError
where
    T: std::fmt::Debug,
{
    FlowyError::internal().context(e)
}

impl lib_dispatch::Error for FlowyError {
    fn as_response(&self) -> EventResponse {
        let bytes: Bytes = self.clone().try_into().unwrap();
        ResponseBuilder::Err().data(bytes).build()
    }
}

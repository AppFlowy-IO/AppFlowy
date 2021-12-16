use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use futures_channel::mpsc::TrySendError;
use std::fmt::Debug;
use strum_macros::Display;
use tokio_tungstenite::tungstenite::{http::StatusCode, Message};
use url::ParseError;

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct WSError {
    #[pb(index = 1)]
    pub code: ErrorCode,

    #[pb(index = 2)]
    pub msg: String,
}

macro_rules! static_ws_error {
    ($name:ident, $status:expr) => {
        #[allow(non_snake_case, missing_docs)]
        pub fn $name() -> WSError {
            WSError {
                code: $status,
                msg: format!("{}", $status),
            }
        }
    };
}

impl WSError {
    #[allow(dead_code)]
    pub(crate) fn new(code: ErrorCode) -> WSError {
        WSError {
            code,
            msg: "".to_string(),
        }
    }

    pub fn context<T: Debug>(mut self, error: T) -> Self {
        self.msg = format!("{:?}", error);
        self
    }

    static_ws_error!(internal, ErrorCode::InternalError);
    static_ws_error!(unsupported_message, ErrorCode::UnsupportedMessage);
    static_ws_error!(unauthorized, ErrorCode::Unauthorized);
}

pub fn internal_error<T>(e: T) -> WSError
where
    T: std::fmt::Debug,
{
    WSError::internal().context(e)
}

#[derive(Debug, Clone, ProtoBuf_Enum, Display, PartialEq, Eq)]
pub enum ErrorCode {
    InternalError      = 0,
    UnsupportedMessage = 1,
    Unauthorized       = 2,
}

impl std::default::Default for ErrorCode {
    fn default() -> Self { ErrorCode::InternalError }
}

impl std::convert::From<url::ParseError> for WSError {
    fn from(error: ParseError) -> Self { WSError::internal().context(error) }
}

impl std::convert::From<protobuf::ProtobufError> for WSError {
    fn from(error: protobuf::ProtobufError) -> Self { WSError::internal().context(error) }
}

impl std::convert::From<futures_channel::mpsc::TrySendError<Message>> for WSError {
    fn from(error: TrySendError<Message>) -> Self { WSError::internal().context(error) }
}

impl std::convert::From<tokio_tungstenite::tungstenite::Error> for WSError {
    fn from(error: tokio_tungstenite::tungstenite::Error) -> Self {
        match error {
            tokio_tungstenite::tungstenite::Error::Http(response) => {
                if response.status() == StatusCode::UNAUTHORIZED {
                    WSError::unauthorized()
                } else {
                    WSError::internal().context(response)
                }
            },
            _ => WSError::internal().context(error),
        }
    }
}

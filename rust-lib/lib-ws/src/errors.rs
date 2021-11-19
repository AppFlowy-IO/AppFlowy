use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use futures_channel::mpsc::TrySendError;
use std::fmt::Debug;
use strum_macros::Display;
use tokio_tungstenite::tungstenite::{http::StatusCode, Message};
use url::ParseError;

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct WsError {
    #[pb(index = 1)]
    pub code: ErrorCode,

    #[pb(index = 2)]
    pub msg: String,
}

macro_rules! static_user_error {
    ($name:ident, $status:expr) => {
        #[allow(non_snake_case, missing_docs)]
        pub fn $name() -> WsError {
            WsError {
                code: $status,
                msg: format!("{}", $status),
            }
        }
    };
}

impl WsError {
    #[allow(dead_code)]
    pub(crate) fn new(code: ErrorCode) -> WsError {
        WsError {
            code,
            msg: "".to_string(),
        }
    }

    pub fn context<T: Debug>(mut self, error: T) -> Self {
        self.msg = format!("{:?}", error);
        self
    }

    static_user_error!(internal, ErrorCode::InternalError);
    static_user_error!(unsupported_message, ErrorCode::UnsupportedMessage);
    static_user_error!(unauthorized, ErrorCode::Unauthorized);
}

pub fn internal_error<T>(e: T) -> WsError
where
    T: std::fmt::Debug,
{
    WsError::internal().context(e)
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

impl std::convert::From<url::ParseError> for WsError {
    fn from(error: ParseError) -> Self { WsError::internal().context(error) }
}

impl std::convert::From<protobuf::ProtobufError> for WsError {
    fn from(error: protobuf::ProtobufError) -> Self { WsError::internal().context(error) }
}

impl std::convert::From<futures_channel::mpsc::TrySendError<Message>> for WsError {
    fn from(error: TrySendError<Message>) -> Self { WsError::internal().context(error) }
}

impl std::convert::From<tokio_tungstenite::tungstenite::Error> for WsError {
    fn from(error: tokio_tungstenite::tungstenite::Error) -> Self {
        let error = match error {
            tokio_tungstenite::tungstenite::Error::Http(response) => {
                if response.status() == StatusCode::UNAUTHORIZED {
                    WsError::unauthorized()
                } else {
                    WsError::internal().context(response)
                }
            },
            _ => WsError::internal().context(error),
        };

        error
    }
}

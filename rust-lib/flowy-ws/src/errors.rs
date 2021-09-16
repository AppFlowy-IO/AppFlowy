use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use futures_channel::mpsc::TrySendError;
use std::fmt::Debug;
use strum_macros::Display;
use tokio_tungstenite::tungstenite::Message;
use url::ParseError;

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct WsError {
    #[pb(index = 1)]
    code: ErrorCode,

    #[pb(index = 2)]
    msg: String,
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
    pub(crate) fn new(code: ErrorCode) -> WsError { WsError { code, msg: "".to_string() } }

    pub fn context<T: Debug>(mut self, error: T) -> Self {
        self.msg = format!("{:?}", error);
        self
    }

    static_user_error!(internal, ErrorCode::InternalError);
}

#[derive(Debug, Clone, ProtoBuf_Enum, Display, PartialEq, Eq)]
pub enum ErrorCode {
    InternalError = 0,
}

impl std::default::Default for ErrorCode {
    fn default() -> Self { ErrorCode::InternalError }
}

impl std::convert::From<url::ParseError> for WsError {
    fn from(error: ParseError) -> Self { WsError::internal().context(error) }
}

impl std::convert::From<futures_channel::mpsc::TrySendError<Message>> for WsError {
    fn from(error: TrySendError<Message>) -> Self { WsError::internal().context(error) }
}

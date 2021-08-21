use serde::{Serialize, __private::Formatter};
use serde_repr::*;
use std::{error::Error, fmt};
use tokio::sync::oneshot::error::RecvError;

#[derive(Debug)]
pub struct ServerError {
    pub code: ServerCode,
    pub msg: String,
}

impl std::fmt::Display for ServerError {
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
        let msg = format!("{:?}:{}", self.code, self.msg);
        f.write_str(&msg)
    }
}

impl std::convert::From<&ServerError> for FlowyResponse<String> {
    fn from(error: &ServerError) -> Self {
        FlowyResponse {
            msg: error.msg.clone(),
            data: None,
            code: error.code.clone(),
        }
    }
}

#[derive(Serialize_repr, Deserialize_repr, PartialEq, Debug, Clone)]
#[repr(u16)]
pub enum ServerCode {
    Success          = 0,
    InvalidToken     = 1,
    InternalError    = 2,
    Unauthorized     = 3,
    PayloadOverflow  = 4,
    PayloadSerdeFail = 5,
    ProtobufError    = 6,
    SerdeError       = 7,
    ConnectRefused   = 8,
    ConnectTimeout   = 9,
    ConnectClose     = 10,
    ConnectCancel    = 11,
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

impl std::convert::From<protobuf::ProtobufError> for ServerError {
    fn from(err: protobuf::ProtobufError) -> Self {
        ServerError {
            code: ServerCode::ProtobufError,
            msg: format!("{}", err),
        }
    }
}

impl std::convert::From<RecvError> for ServerError {
    fn from(error: RecvError) -> Self {
        ServerError {
            code: ServerCode::InternalError,
            msg: format!("{:?}", error),
        }
    }
}

impl std::convert::From<reqwest::Error> for ServerError {
    fn from(error: reqwest::Error) -> Self {
        if error.is_timeout() {
            return ServerError {
                code: ServerCode::ConnectTimeout,
                msg: format!("{}", error),
            };
        }

        if error.is_request() {
            let hyper_error: Option<&hyper::Error> = error.source().unwrap().downcast_ref();
            return match hyper_error {
                None => ServerError {
                    code: ServerCode::ConnectRefused,
                    msg: format!("{:?}", error),
                },
                Some(hyper_error) => {
                    let mut code = ServerCode::InternalError;
                    let msg = format!("{}", error);
                    if hyper_error.is_closed() {
                        code = ServerCode::ConnectClose;
                    }

                    if hyper_error.is_connect() {
                        code = ServerCode::ConnectRefused;
                    }

                    if hyper_error.is_canceled() {
                        code = ServerCode::ConnectCancel;
                    }

                    if hyper_error.is_timeout() {

                    }

                    ServerError { code, msg }
                },
            };
        }

        let msg = format!("{:?}", error);
        ServerError {
            code: ServerCode::ProtobufError,
            msg,
        }
    }
}

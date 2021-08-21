use crate::response::FlowyResponse;
use protobuf::ProtobufError;
use std::fmt::{Formatter, Write};

// #[derive(Debug)]
// pub struct ServerError {
//     code: ErrorCode
// }
//
// pub enum ErrorCode {
//     InternalError(String),
//     ProtobufError(ProtobufError),
//     BadRequest(FlowyResponse<String>),
//     Unauthorized,
// }
//
//
// impl std::fmt::Display for ErrorCode {
//     fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
//         match self {
//             ErrorCode::InternalError(_) => f.write_str("Internal Server
// Error"),             ErrorCode::ProtobufError(err) =>
// f.write_str(&format!("protobuf error: {}", err)),             
// ErrorCode::BadRequest(request) => {                 let msg = format!("Bad
// Request: {:?}", request);                 f.write_str(&msg)
//             },
//             ErrorCode::Unauthorized => f.write_str("Unauthorized"),
//         }
//     }
// }

// impl std::convert::From<ProtobufError> for ServerCode {
//     fn from(err: ProtobufError) -> Self { ServerCode::ProtobufError(err) }
// }
//
// impl std::convert::From<reqwest::Error> for ServerError {
//     fn from(error: reqwest::Error) -> Self {
//         let msg = format!("{:?}", error);
//         ServerError::InternalError(msg)
//     }
// }
//
// impl std::convert::From<String> for ServerError {
//     fn from(error: String) -> Self { ServerError::InternalError(error) }
// }

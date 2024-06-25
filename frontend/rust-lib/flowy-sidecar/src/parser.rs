use crate::error::{ReadError, RemoteError};
use crate::rpc_object::RpcObject;
use serde_json::{json, Value};
use std::io::BufRead;

#[derive(Debug, Default)]
pub struct MessageReader(String);

impl MessageReader {
  /// Attempts to read the next line from the stream and parse it as
  /// an RPC object.
  ///
  /// # Errors
  ///
  /// This function will return an error if there is an underlying
  /// I/O error, if the stream is closed, or if the message is not
  /// a valid JSON object.
  pub fn next<R: BufRead>(&mut self, reader: &mut R) -> Result<RpcObject, ReadError> {
    self.0.clear();
    let _ = reader.read_line(&mut self.0)?;
    if self.0.is_empty() {
      Err(ReadError::Disconnect)
    } else {
      self.parse(&self.0)
    }
  }

  /// Attempts to parse a &str as an RPC Object.
  ///
  /// This should not be called directly unless you are writing tests.
  #[doc(hidden)]
  pub fn parse(&self, s: &str) -> Result<RpcObject, ReadError> {
    match serde_json::from_str::<Value>(s) {
      Ok(val) => {
        if !val.is_object() {
          Err(ReadError::NotObject(s.to_string()))
        } else {
          Ok(val.into())
        }
      },
      Err(_) => Ok(RpcObject(json!({"message": s.to_string()}))),
    }
  }
}

pub type RequestId = u64;
#[derive(Debug, Clone, PartialEq)]
/// An RPC call, which may be either a notification or a request.
pub enum Call<R> {
  Message(Value),
  /// An id and an RPC Request
  Request(RequestId, R),
  /// A malformed request: the request contained an id, but could
  /// not be parsed. The client will receive an error.
  InvalidRequest(RequestId, RemoteError),
}

pub trait ResponseParser {
  type ValueType;
  fn parse_response(json: serde_json::Value) -> Result<Self::ValueType, RemoteError>;
}

pub struct ChatResponseParser;
impl ResponseParser for ChatResponseParser {
  type ValueType = String;

  fn parse_response(json: Value) -> Result<Self::ValueType, RemoteError> {
    if json.is_object() {
      if let Some(message) = json.get("data") {
        if let Some(message) = message.as_str() {
          return Ok(message.to_string());
        }
      }
    }
    return Err(RemoteError::InvalidResponse(json));
  }
}

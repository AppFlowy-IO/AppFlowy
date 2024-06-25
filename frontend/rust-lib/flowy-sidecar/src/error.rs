use serde::{Deserialize, Deserializer, Serialize, Serializer};
use serde_json::{json, Value};
use std::{fmt, io};

/// The error type of `tauri-utils`.
#[derive(Debug, thiserror::Error)]
pub enum Error {
  /// An IO error occurred on the underlying communication channel.
  #[error(transparent)]
  Io(#[from] io::Error),
  /// The peer returned an error.
  #[error("Remote error: {0}")]
  RemoteError(RemoteError),
  /// The peer closed the connection.
  #[error("Peer closed the connection.")]
  PeerDisconnect,
  /// The peer sent a response containing the id, but was malformed.
  #[error("Invalid response.")]
  InvalidResponse,
}

#[derive(Debug)]
pub enum ReadError {
  /// An error occurred in the underlying stream
  Io(io::Error),
  /// The message was not valid JSON.
  Json(serde_json::Error),
  /// The message was not a JSON object.
  NotObject(String),
  /// The the method and params were not recognized by the handler.
  UnknownRequest(serde_json::Error),
  /// The peer closed the connection.
  Disconnect,
}

#[derive(Debug, Clone, PartialEq, thiserror::Error)]
pub enum RemoteError {
  /// The JSON was valid, but was not a correctly formed request.
  ///
  /// This Error is used internally, and should not be returned by
  /// clients.
  #[error("Invalid request: {0:?}")]
  InvalidRequest(Option<Value>),

  #[error("Invalid response: {0}")]
  InvalidResponse(Value),
  /// A custom error, defined by the client.
  #[error("Custom error: {message}")]
  Custom {
    code: i64,
    message: String,
    data: Option<Value>,
  },
  /// An error that cannot be represented by an error object.
  ///
  /// This error is intended to accommodate clients that return arbitrary
  /// error values. It should not be used for new errors.
  #[error("Unknown error: {0}")]
  Unknown(Value),
}

impl ReadError {
  /// Returns `true` iff this is the `ReadError::Disconnect` variant.
  pub fn is_disconnect(&self) -> bool {
    matches!(*self, ReadError::Disconnect)
  }
}

impl fmt::Display for ReadError {
  fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
    match self {
      ReadError::Io(ref err) => write!(f, "I/O Error: {:?}", err),
      ReadError::Json(ref err) => write!(f, "JSON Error: {:?}", err),
      ReadError::NotObject(s) => write!(f, "Expected JSON object, found: {}", s),
      ReadError::UnknownRequest(ref err) => write!(f, "Unknown request: {:?}", err),
      ReadError::Disconnect => write!(f, "Peer closed the connection."),
    }
  }
}

impl From<serde_json::Error> for ReadError {
  fn from(err: serde_json::Error) -> ReadError {
    ReadError::Json(err)
  }
}

impl From<io::Error> for ReadError {
  fn from(err: io::Error) -> ReadError {
    ReadError::Io(err)
  }
}

impl From<serde_json::Error> for RemoteError {
  fn from(err: serde_json::Error) -> RemoteError {
    RemoteError::InvalidRequest(Some(json!(err.to_string())))
  }
}

impl From<RemoteError> for Error {
  fn from(err: RemoteError) -> Error {
    Error::RemoteError(err)
  }
}

#[derive(Deserialize, Serialize)]
struct ErrorHelper {
  code: i64,
  message: String,
  #[serde(skip_serializing_if = "Option::is_none")]
  data: Option<Value>,
}

impl<'de> Deserialize<'de> for RemoteError {
  fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
  where
    D: Deserializer<'de>,
  {
    let v = Value::deserialize(deserializer)?;
    let resp = match ErrorHelper::deserialize(&v) {
      Ok(resp) => resp,
      Err(_) => return Ok(RemoteError::Unknown(v)),
    };

    Ok(match resp.code {
      -32600 => RemoteError::InvalidRequest(resp.data),
      _ => RemoteError::Custom {
        code: resp.code,
        message: resp.message,
        data: resp.data,
      },
    })
  }
}

impl Serialize for RemoteError {
  fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
  where
    S: Serializer,
  {
    let (code, message, data) = match self {
      RemoteError::InvalidRequest(ref d) => (-32600, "Invalid request".to_string(), d.clone()),
      RemoteError::Custom {
        code,
        ref message,
        ref data,
      } => (*code, message.clone(), data.clone()),
      RemoteError::Unknown(_) => {
        panic!("The 'Unknown' error variant is not intended for client use.")
      },
      RemoteError::InvalidResponse(s) => (-1, "Invalid response".to_string(), Some(s.clone())),
    };
    let err = ErrorHelper {
      code,
      message,
      data,
    };
    err.serialize(serializer)
  }
}

use crate::parser::{Call, RequestId};
use crate::rpc_peer::Response;
use serde::de::{DeserializeOwned, Error};
use serde_json::Value;

#[derive(Debug, Clone)]
pub struct RpcObject(pub Value);

impl RpcObject {
  /// Returns the 'id' of the underlying object, if present.
  pub fn get_id(&self) -> Option<RequestId> {
    self.0.get("id").and_then(Value::as_u64)
  }

  /// Returns the 'method' field of the underlying object, if present.
  pub fn get_method(&self) -> Option<&str> {
    self.0.get("method").and_then(Value::as_str)
  }

  /// Returns `true` if this object looks like an RPC response;
  /// that is, if it has an 'id' field and does _not_ have a 'method'
  /// field.
  pub fn is_response(&self) -> bool {
    self.0.get("id").is_some() && self.0.get("method").is_none()
  }

  /// Converts the underlying `Value` into an RPC response object.
  /// The caller should verify that the object is a response before calling this method.
  /// # Errors
  /// If the `Value` is not a well-formed response object, this returns a `String` containing an
  /// error message. The caller should print this message and exit.
  pub fn into_response(mut self) -> Result<Response, String> {
    let _ = self
      .get_id()
      .ok_or("Response requires 'id' field.".to_string())?;

    if self.0.get("result").is_some() == self.0.get("error").is_some() {
      return Err("RPC response must contain exactly one of 'error' or 'result' fields.".into());
    }
    let result = self.0.as_object_mut().and_then(|obj| obj.remove("result"));
    match result {
      Some(r) => Ok(Ok(r)),
      None => {
        let error = self
          .0
          .as_object_mut()
          .and_then(|obj| obj.remove("error"))
          .unwrap();
        Err(format!("Error handling response: {:?}", error))
      },
    }
  }

  /// Converts the underlying `Value` into either an RPC notification or request.
  pub fn into_rpc<R>(self) -> Result<Call<R>, serde_json::Error>
  where
    R: DeserializeOwned,
  {
    let id = self.get_id();
    match id {
      Some(id) => match serde_json::from_value::<R>(self.0) {
        Ok(resp) => Ok(Call::Request(id, resp)),
        Err(err) => Ok(Call::InvalidRequest(id, err.into())),
      },
      None => match self.0.get("message").and_then(|value| value.as_str()) {
        None => Err(serde_json::Error::missing_field("message")),
        Some(s) => Ok(Call::Message(s.to_string().into())),
      },
    }
  }
}

impl From<Value> for RpcObject {
  fn from(v: Value) -> RpcObject {
    RpcObject(v)
  }
}

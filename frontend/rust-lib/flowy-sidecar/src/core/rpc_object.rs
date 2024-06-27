use crate::core::parser::{Call, RequestId};
use crate::core::rpc_peer::{Response, ResponsePayload};
use crate::error::RemoteError;
use serde::de::{DeserializeOwned, Error};
use serde_json::{json, Value};

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

  /// Converts a JSON-RPC response into a structured `Response` object.
  ///
  /// This function validates and parses a JSON-RPC response, ensuring it contains the necessary fields,
  /// and then transforms it into a structured `Response` object. The response must contain either a
  /// "result" or an "error" field, but not both. If the response contains a "result" field, it may also
  /// include streaming data, indicated by a nested "stream" field.
  ///
  /// # Errors
  ///
  /// This function will return an error if:
  /// - The "id" field is missing.
  /// - The response contains both "result" and "error" fields, or neither.
  /// - The "stream" field within the "result" is missing "type" or "data" fields.
  /// - The "stream" type is invalid (i.e., not "streaming" or "end").
  ///
  /// # Returns
  ///
  /// - `Ok(Ok(ResponsePayload::Json(result)))`: If the response contains a valid "result".
  /// - `Ok(Ok(ResponsePayload::Streaming(data)))`: If the response contains streaming data of type "streaming".
  /// - `Ok(Ok(ResponsePayload::StreamEnd(json!({}))))`: If the response contains streaming data of type "end".
  /// - `Err(String)`: If any validation or parsing errors occur.
  ///.
  pub fn into_response(mut self) -> Result<Response, String> {
    // Ensure 'id' field is present
    self
      .get_id()
      .ok_or_else(|| "Response requires 'id' field.".to_string())?;

    // Ensure the response contains exactly one of 'result' or 'error'
    let has_result = self.0.get("result").is_some();
    let has_error = self.0.get("error").is_some();
    if has_result == has_error {
      return Err("RPC response must contain exactly one of 'error' or 'result' fields.".into());
    }

    // Handle the 'result' field if present
    if let Some(mut result) = self.0.as_object_mut().and_then(|obj| obj.remove("result")) {
      if let Some(mut stream) = result.as_object_mut().and_then(|obj| obj.remove("stream")) {
        if let Some((has_more, data)) = stream.as_object_mut().and_then(|obj| {
          let has_more = obj.remove("has_more")?.as_bool().unwrap_or(false);
          let data = obj.remove("data")?;
          Some((has_more, data))
        }) {
          return match has_more {
            true => Ok(Ok(ResponsePayload::Streaming(data))),
            false => Ok(Ok(ResponsePayload::StreamEnd(data))),
          };
        } else {
          return Err("Stream response must contain 'type' and 'data' fields.".into());
        }
      }

      Ok(Ok(ResponsePayload::Json(result)))
    } else {
      // Handle the 'error' field
      let error = self.0.as_object_mut().unwrap().remove("error").unwrap();
      Err(format!("Error handling response: {:?}", error))
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

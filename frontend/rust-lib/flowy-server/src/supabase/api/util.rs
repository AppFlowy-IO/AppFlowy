use anyhow::Error;
use anyhow::Result;
use reqwest::{Response, StatusCode};
use serde_json::Value;

use flowy_encrypt::{decrypt_bytes, encrypt_bytes};
use flowy_error::{ErrorCode, FlowyError};
use lib_infra::future::{to_fut, Fut};

#[derive(Default)]
pub struct InsertParamsBuilder {
  map: serde_json::Map<String, Value>,
}

impl InsertParamsBuilder {
  pub fn new() -> Self {
    Self::default()
  }

  pub fn insert<T: serde::Serialize>(mut self, key: &str, value: T) -> Self {
    self
      .map
      .insert(key.to_string(), serde_json::to_value(value).unwrap());
    self
  }

  pub fn build(self) -> String {
    serde_json::to_string(&self.map).unwrap()
  }
}
/// Trait `ExtendedResponse` provides an extension method to handle and transform the response data.
///
/// This trait introduces a single method:
///
/// - `get_value`: It extracts the value from the response, and returns it as an instance of a type `T`.
/// This method will return an error if the status code of the response signifies a failure (not success).
/// Otherwise, it attempts to parse the response body into an instance of type `T`, which must implement
/// `serde::de::DeserializeOwned`, `Send`, `Sync`, and have a static lifetime ('static).
pub trait ExtendedResponse {
  /// Returns the value of the response as a Future of `Result<T, Error>`.
  ///
  /// If the status code of the response is not a success, returns an `Error`.
  /// Otherwise, attempts to parse the response into an instance of type `T`.
  ///
  /// # Type Parameters
  ///
  /// * `T`: The type of the value to be returned. Must implement `serde::de::DeserializeOwned`,
  /// `Send`, `Sync`, and have a static lifetime ('static).
  fn get_value<T>(self) -> Fut<Result<T, Error>>
  where
    T: serde::de::DeserializeOwned + Send + Sync + 'static;

  fn get_json(self) -> Fut<Result<Value, Error>>;

  fn success(self) -> Fut<Result<(), Error>>;

  fn success_with_body(self) -> Fut<Result<String, Error>>;
}

impl ExtendedResponse for Response {
  fn get_value<T>(self) -> Fut<Result<T, Error>>
  where
    T: serde::de::DeserializeOwned + Send + Sync + 'static,
  {
    to_fut(async move {
      let status_code = self.status();
      if !status_code.is_success() {
        return Err(parse_response_as_error(self).await.into());
      }
      let bytes = self.bytes().await?;
      let value = serde_json::from_slice(&bytes).map_err(|e| {
        FlowyError::new(
          ErrorCode::Serde,
          format!(
            "failed to parse json: {}, body: {}",
            e,
            String::from_utf8_lossy(&bytes)
          ),
        )
      })?;
      Ok(value)
    })
  }

  fn get_json(self) -> Fut<Result<Value, Error>> {
    to_fut(async move {
      if !self.status().is_success() {
        return Err(parse_response_as_error(self).await.into());
      }
      let bytes = self.bytes().await?;
      let value = serde_json::from_slice::<Value>(&bytes)?;
      Ok(value)
    })
  }

  fn success(self) -> Fut<Result<(), Error>> {
    to_fut(async move {
      if !self.status().is_success() {
        return Err(parse_response_as_error(self).await.into());
      }
      Ok(())
    })
  }

  fn success_with_body(self) -> Fut<Result<String, Error>> {
    to_fut(async move {
      if !self.status().is_success() {
        return Err(parse_response_as_error(self).await.into());
      }
      Ok(self.text().await?)
    })
  }
}

async fn parse_response_as_error(response: Response) -> FlowyError {
  let status_code = response.status();
  let msg = response.text().await.unwrap_or_default();
  if status_code == StatusCode::CONFLICT {
    return FlowyError::new(ErrorCode::Conflict, msg);
  }

  FlowyError::new(
    ErrorCode::HttpError,
    format!(
      "expected status code 2XX, but got {}, body: {}",
      status_code, msg
    ),
  )
}
/// An encoder for binary columns in Supabase.
///
/// Provides utilities to encode binary data into a format suitable for Supabase columns.
pub struct SupabaseBinaryColumnEncoder;

impl SupabaseBinaryColumnEncoder {
  /// Encodes the given binary data into a Supabase-friendly string representation.
  ///
  /// # Parameters
  /// - `value`: The binary data to encode.
  ///
  /// # Returns
  /// Returns the encoded string in the format: `\\xHEX_ENCODED_STRING`
  pub fn encode<T: AsRef<[u8]>>(
    value: T,
    encryption_secret: &Option<String>,
  ) -> Result<(String, i32)> {
    let encrypt = if encryption_secret.is_some() { 1 } else { 0 };
    let value = match encryption_secret {
      None => hex::encode(value),
      Some(encryption_secret) => {
        let encrypt_data = encrypt_bytes(value, encryption_secret)?;
        hex::encode(encrypt_data)
      },
    };

    Ok((format!("\\x{}", value), encrypt))
  }
}

/// A decoder for binary columns in Supabase.
///
/// Provides utilities to decode a string from Supabase columns back into binary data.
pub struct SupabaseBinaryColumnDecoder;

impl SupabaseBinaryColumnDecoder {
  /// Decodes a Supabase binary column string into binary data.
  ///
  /// # Parameters
  /// - `value`: The string representation from a Supabase binary column.
  ///
  /// # Returns
  /// Returns an `Option` containing the decoded binary data if decoding is successful.
  /// Otherwise, returns `None`.
  pub fn decode<T: AsRef<str>>(
    value: T,
    encrypt: i32,
    encryption_secret: &Option<String>,
  ) -> Result<Vec<u8>> {
    let s = value
      .as_ref()
      .strip_prefix("\\x")
      .ok_or(anyhow::anyhow!("Value is not start with: \\x",))?;

    if encrypt == 0 {
      let bytes = hex::decode(s)?;
      Ok(bytes)
    } else {
      match encryption_secret {
        None => Err(anyhow::anyhow!(
          "encryption_secret is None, but encrypt is 1"
        )),
        Some(encryption_secret) => {
          let encrypt_data = hex::decode(s)?;
          decrypt_bytes(encrypt_data, encryption_secret)
        },
      }
    }
  }
}

/// A decoder specifically tailored for realtime event binary columns in Supabase.
///
pub struct SupabaseRealtimeEventBinaryColumnDecoder;

impl SupabaseRealtimeEventBinaryColumnDecoder {
  /// The realtime event binary column string is encoded twice. So it needs to be decoded twice.
  pub fn decode<T: AsRef<str>>(value: T) -> Option<Vec<u8>> {
    let s = value.as_ref().strip_prefix("\\x")?;
    let bytes = hex::decode(s).ok()?;
    hex::decode(bytes).ok()
  }
}

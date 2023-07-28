use anyhow::Error;
use reqwest::{Response, StatusCode};
use serde_json::Value;

use flowy_error::{ErrorCode, FlowyError};
use lib_infra::future::{to_fut, Fut};

pub struct InsertParamsBuilder {
  map: serde_json::Map<String, Value>,
}

impl InsertParamsBuilder {
  pub fn new() -> Self {
    Self {
      map: serde_json::Map::new(),
    }
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

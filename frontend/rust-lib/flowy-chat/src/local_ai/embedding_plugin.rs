use anyhow::anyhow;
use flowy_sidecar::core::parser::ResponseParser;
use flowy_sidecar::core::plugin::Plugin;
use flowy_sidecar::error::{RemoteError, SidecarError};
use serde_json::json;
use serde_json::Value as JsonValue;
use std::sync::Weak;

pub struct EmbeddingPluginOperation {
  plugin: Weak<Plugin>,
}

impl EmbeddingPluginOperation {
  pub fn new(plugin: Weak<Plugin>) -> Self {
    EmbeddingPluginOperation { plugin }
  }

  pub async fn get_embeddings(&self, message: &str) -> Result<Vec<Vec<f64>>, SidecarError> {
    let plugin = self
      .plugin
      .upgrade()
      .ok_or(SidecarError::Internal(anyhow!("Plugin is dropped")))?;
    let params = json!({"method": "get_embeddings", "params": {"input": message }});
    plugin
      .async_request::<EmbeddingResponseParse>("handle", &params)
      .await
  }
}

pub struct EmbeddingResponseParse;
impl ResponseParser for EmbeddingResponseParse {
  type ValueType = Vec<Vec<f64>>;

  fn parse_json(json: JsonValue) -> Result<Self::ValueType, RemoteError> {
    if json.is_object() {
      if let Some(data) = json.get("data") {
        if let Some(embeddings) = data.get("embeddings") {
          if let Some(array) = embeddings.as_array() {
            let mut result = Vec::new();
            for item in array {
              if let Some(inner_array) = item.as_array() {
                let mut inner_result = Vec::new();
                for num in inner_array {
                  if let Some(value) = num.as_f64() {
                    inner_result.push(value);
                  } else {
                    return Err(RemoteError::ParseResponse(json));
                  }
                }
                result.push(inner_result);
              } else {
                return Err(RemoteError::ParseResponse(json));
              }
            }
            return Ok(result);
          }
        }
      }
    }
    Err(RemoteError::ParseResponse(json))
  }
}

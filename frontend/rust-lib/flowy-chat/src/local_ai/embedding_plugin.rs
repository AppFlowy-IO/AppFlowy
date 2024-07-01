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

  pub async fn calculate_similarity(
    &self,
    message1: &str,
    message2: &str,
  ) -> Result<f64, SidecarError> {
    let plugin = self
      .plugin
      .upgrade()
      .ok_or(SidecarError::Internal(anyhow!("Plugin is dropped")))?;
    let params =
      json!({"method": "calculate_similarity", "params": {"src": message1, "dest": message2}});
    plugin
      .async_request::<SimilarityResponseParser>("handle", &params)
      .await
  }
}

pub struct SimilarityResponseParser;
impl ResponseParser for SimilarityResponseParser {
  type ValueType = f64;

  fn parse_json(json: JsonValue) -> Result<Self::ValueType, RemoteError> {
    if json.is_object() {
      if let Some(data) = json.get("data") {
        if let Some(score) = data.get("score").and_then(|v| v.as_f64()) {
          return Ok(score);
        }
      }
    }

    Err(RemoteError::ParseResponse(json))
  }
}

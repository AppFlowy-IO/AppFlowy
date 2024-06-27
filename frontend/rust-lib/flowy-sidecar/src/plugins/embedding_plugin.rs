use crate::core::parser::SimilarityResponseParser;
use crate::core::plugin::Plugin;
use crate::error::SidecarError;
use anyhow::anyhow;
use serde_json::json;
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

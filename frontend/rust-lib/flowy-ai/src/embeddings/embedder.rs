use crate::local_ai::client::AIClient;
use flowy_error::FlowyResult;
use std::sync::Arc;

/// Pairs the configured backend with the embedding model to use.
///
/// The model name lives here because it is provider-specific (`nomic-embed-text:latest` for Ollama
/// versus `text-embedding-3-small` for OpenAI-compatible endpoints) and callers should not need to
/// know which backend is active. Regardless of provider the vectors are always
/// [`crate::local_ai::client::EMBEDDING_DIMENSION`] long.
#[derive(Debug, Clone)]
pub struct Embedder {
  client: Arc<AIClient>,
  model: String,
}

impl Embedder {
  pub fn new(client: Arc<AIClient>, model: String) -> Self {
    Self { client, model }
  }

  /// Returns one vector per input string, in the same order.
  pub async fn embed(&self, input: Vec<String>) -> FlowyResult<Vec<Vec<f32>>> {
    self.client.embed(&self.model, input).await
  }

  pub fn model_name(&self) -> &str {
    &self.model
  }
}

use async_trait::async_trait;
use futures::Stream;
use langchain_rust::language_models::llm::LLM;
use langchain_rust::language_models::{GenerateResult, LLMError};
use langchain_rust::schemas::{Message, StreamData};
use std::pin::Pin;
use std::sync::Arc;

use crate::local_ai::client::AIClient;
use ollama_rs::generation::parameters::FormatType;
use ollama_rs::models::ModelOptions;

/// The [`LLM`] implementation backing every chain in this crate.
///
/// The name is historical: it now dispatches to whichever backend the user configured — Ollama or
/// an OpenAI-compatible endpoint — through [`AIClient`]. Keeping this type concrete rather than
/// making the chains generic over the backend is what keeps the provider change contained to this
/// file.
#[derive(Debug, Clone)]
pub struct LLMOllama {
  pub model_name: String,
  client: Arc<AIClient>,
  format: Option<FormatType>,
  /// Ollama-specific sampling parameters. The OpenAI-compatible backend ignores these.
  options: Option<ModelOptions>,
}

impl LLMOllama {
  pub fn new(
    model: &str,
    client: Arc<AIClient>,
    format: Option<FormatType>,
    options: Option<ModelOptions>,
  ) -> Self {
    LLMOllama {
      model_name: model.to_string(),
      client,
      format,
      options,
    }
  }

  pub fn with_options(mut self, options: ModelOptions) -> Self {
    self.options = Some(options);
    self
  }

  pub fn with_format(mut self, format: FormatType) -> Self {
    self.format = Some(format);
    self
  }

  pub fn with_model(mut self, model: &str) -> Self {
    self.model_name = model.to_string();
    self
  }

  pub fn set_model(&mut self, model: &str) {
    self.model_name = model.to_string();
  }
}

#[async_trait]
impl LLM for LLMOllama {
  async fn generate(&self, messages: &[Message]) -> Result<GenerateResult, LLMError> {
    self
      .client
      .chat(
        &self.model_name,
        messages,
        self.format.as_ref(),
        self.options.as_ref(),
      )
      .await
  }

  async fn stream(
    &self,
    messages: &[Message],
  ) -> Result<Pin<Box<dyn Stream<Item = Result<StreamData, LLMError>> + Send>>, LLMError> {
    self
      .client
      .chat_stream(
        &self.model_name,
        messages,
        self.format.as_ref(),
        self.options.as_ref(),
      )
      .await
  }
}

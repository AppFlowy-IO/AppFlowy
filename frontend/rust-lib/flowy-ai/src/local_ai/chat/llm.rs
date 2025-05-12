use async_trait::async_trait;
use futures::Stream;
use langchain_rust::language_models::llm::LLM;
use langchain_rust::language_models::{GenerateResult, LLMError, TokenUsage};
use langchain_rust::schemas::{Message, StreamData};
use ollama_rs::error::OllamaError;
use std::pin::Pin;
use std::sync::Arc;
use tokio_stream::StreamExt;

use ollama_rs::generation::chat::request::ChatMessageRequest;
use ollama_rs::generation::parameters::FormatType;
use ollama_rs::models::ModelOptions;
use ollama_rs::Ollama;

#[derive(Debug, Clone)]
pub struct LLMOllama {
  pub model_name: String,
  ollama: Arc<Ollama>,
  format: Option<FormatType>,
  options: Option<ModelOptions>,
}

impl Default for LLMOllama {
  fn default() -> Self {
    LLMOllama {
      model_name: "llama3.1".to_string(),
      ollama: Arc::new(Ollama::default()),
      format: None,
      options: None,
    }
  }
}

impl LLMOllama {
  pub fn new(
    model: &str,
    ollama: Arc<Ollama>,
    format: Option<FormatType>,
    options: Option<ModelOptions>,
  ) -> Self {
    LLMOllama {
      model_name: model.to_string(),
      ollama,
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

  fn generate_request(&self, messages: &[Message]) -> ChatMessageRequest {
    let mapped_messages = messages.iter().map(|message| message.into()).collect();
    let mut request = ChatMessageRequest::new(self.model_name.clone(), mapped_messages);
    if let Some(option) = &self.options {
      request = request.options(option.clone())
    }
    if let Some(format) = &self.format {
      request = request.format(format.clone());
    }
    request
  }
}

#[async_trait]
impl LLM for LLMOllama {
  async fn generate(&self, messages: &[Message]) -> Result<GenerateResult, LLMError> {
    let request = self.generate_request(messages);
    let result = self.ollama.send_chat_messages(request).await?;
    let generation = result.message.content;
    let tokens = result.final_data.map(|final_data| {
      let prompt_tokens = final_data.prompt_eval_count as u32;
      let completion_tokens = final_data.eval_count as u32;
      TokenUsage {
        prompt_tokens,
        completion_tokens,
        total_tokens: prompt_tokens + completion_tokens,
      }
    });

    Ok(GenerateResult { tokens, generation })
  }

  async fn stream(
    &self,
    messages: &[Message],
  ) -> Result<Pin<Box<dyn Stream<Item = Result<StreamData, LLMError>> + Send>>, LLMError> {
    let request = self.generate_request(messages);
    let result = self.ollama.send_chat_messages_stream(request).await?;

    let stream = result.map(|data| match data {
      Ok(data) => Ok(StreamData::new(
        serde_json::to_value(&data).unwrap_or_default(),
        None,
        data.message.content,
      )),
      Err(_) => Err(OllamaError::Other("Stream error".to_string()).into()),
    });

    Ok(Box::pin(stream))
  }
}

use async_openai::Client as OpenAIHttpClient;
use async_openai::config::OpenAIConfig;
use async_openai::types::{
  ChatCompletionRequestAssistantMessageArgs, ChatCompletionRequestMessage,
  ChatCompletionRequestSystemMessageArgs, ChatCompletionRequestUserMessageArgs,
  CreateChatCompletionRequestArgs, CreateEmbeddingRequestArgs, EmbeddingInput, ResponseFormat,
};
use flowy_error::{FlowyError, FlowyResult};
use futures::Stream;
use langchain_rust::language_models::{GenerateResult, LLMError, TokenUsage};
use langchain_rust::schemas::{Message, MessageType, StreamData};
use ollama_rs::Ollama;
use ollama_rs::generation::chat::request::ChatMessageRequest;
use ollama_rs::generation::embeddings::request::{EmbeddingsInput, GenerateEmbeddingsRequest};
use ollama_rs::generation::parameters::FormatType;
use ollama_rs::models::ModelOptions;
use serde::{Deserialize, Serialize};
use std::pin::Pin;
use std::sync::Arc;
use tokio_stream::StreamExt;

/// The vector store column is declared as `float[768]` (see
/// flowy-sqlite-vec/migrations/001-init/up.sql), so every provider must yield vectors of exactly
/// this size or the embeddings cannot be stored.
pub const EMBEDDING_DIMENSION: usize = 768;

#[derive(Clone, Copy, Debug, Default, PartialEq, Eq, Serialize, Deserialize)]
pub enum AIProvider {
  #[default]
  Ollama,
  /// Any endpoint speaking the OpenAI REST API: OpenAI itself, LM Studio, vLLM, llama.cpp,
  /// OpenRouter, Groq, Together, ...
  OpenAI,
}

/// A chat/embedding backend. Both variants expose the same operations so the rest of the crate
/// never branches on the provider.
pub enum AIClient {
  Ollama(Arc<Ollama>),
  OpenAI {
    client: Box<OpenAIHttpClient<OpenAIConfig>>,
    base_url: String,
    api_key: String,
  },
}

impl std::fmt::Debug for AIClient {
  fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
    match self {
      AIClient::Ollama(o) => write!(f, "AIClient::Ollama({})", o.url_str()),
      AIClient::OpenAI { base_url, .. } => write!(f, "AIClient::OpenAI({})", base_url),
    }
  }
}

impl AIClient {
  pub fn new(provider: AIProvider, base_url: &str, api_key: &str) -> FlowyResult<Self> {
    match provider {
      AIProvider::Ollama => {
        let ollama = Ollama::try_new(base_url).map_err(|err| {
          FlowyError::local_ai().with_context(format!("invalid ollama url {}: {}", base_url, err))
        })?;
        Ok(AIClient::Ollama(Arc::new(ollama)))
      },
      AIProvider::OpenAI => {
        // Trailing slashes produce `//chat/completions` on some gateways.
        let base_url = base_url.trim_end_matches('/').to_string();
        let mut config = OpenAIConfig::new().with_api_base(&base_url);
        // Local servers (LM Studio, llama.cpp) usually accept any key, but async-openai always
        // sends the header, so only override when the user actually supplied one.
        if !api_key.is_empty() {
          config = config.with_api_key(api_key);
        }
        Ok(AIClient::OpenAI {
          client: Box::new(OpenAIHttpClient::with_config(config)),
          base_url,
          api_key: api_key.to_string(),
        })
      },
    }
  }

  pub fn base_url(&self) -> String {
    match self {
      AIClient::Ollama(o) => o.url_str().to_string(),
      AIClient::OpenAI { base_url, .. } => base_url.clone(),
    }
  }

  pub fn provider(&self) -> AIProvider {
    match self {
      AIClient::Ollama(_) => AIProvider::Ollama,
      AIClient::OpenAI { .. } => AIProvider::OpenAI,
    }
  }

  /// Whether this client is already configured exactly as requested, so callers can skip a reload.
  /// The url crate normalises `http://host:1234` to a trailing slash, hence the trim on both sides.
  pub fn matches(&self, provider: AIProvider, base_url: &str, api_key: &str) -> bool {
    if self.provider() != provider {
      return false;
    }
    if self.base_url().trim_end_matches('/') != base_url.trim_end_matches('/') {
      return false;
    }
    match self {
      AIClient::Ollama(_) => true,
      AIClient::OpenAI { api_key: key, .. } => key == api_key,
    }
  }

  /// Whether two clients are configured identically.
  pub fn same_as(&self, other: &AIClient) -> bool {
    match other {
      AIClient::Ollama(_) => self.matches(other.provider(), &other.base_url(), ""),
      AIClient::OpenAI { api_key, .. } => self.matches(other.provider(), &other.base_url(), api_key),
    }
  }

  pub fn as_ollama(&self) -> Option<&Arc<Ollama>> {
    match self {
      AIClient::Ollama(o) => Some(o),
      AIClient::OpenAI { .. } => None,
    }
  }

  /// Model names available on the backend.
  pub async fn list_models(&self) -> FlowyResult<Vec<String>> {
    match self {
      AIClient::Ollama(ollama) => {
        let models = ollama
          .list_local_models()
          .await
          .map_err(|err| FlowyError::local_ai().with_context(err.to_string()))?;
        Ok(models.into_iter().map(|m| m.name).collect())
      },
      AIClient::OpenAI { client, .. } => {
        let models = client
          .models()
          .list()
          .await
          .map_err(|err| FlowyError::local_ai().with_context(err.to_string()))?;
        Ok(models.data.into_iter().map(|m| m.id).collect())
      },
    }
  }

  /// Embed `input`, returning one vector per input string. Every vector is verified to be
  /// [`EMBEDDING_DIMENSION`] long so a mis-sized model fails here rather than at insert time.
  pub async fn embed(&self, model: &str, input: Vec<String>) -> FlowyResult<Vec<Vec<f32>>> {
    let embeddings = match self {
      AIClient::Ollama(ollama) => {
        let request =
          GenerateEmbeddingsRequest::new(model.to_string(), EmbeddingsInput::Multiple(input));
        ollama
          .generate_embeddings(request)
          .await
          .map_err(|err| FlowyError::local_ai().with_context(err.to_string()))?
          .embeddings
      },
      AIClient::OpenAI { client, .. } => {
        let request = CreateEmbeddingRequestArgs::default()
          .model(model)
          .input(EmbeddingInput::StringArray(input))
          // text-embedding-3-* are Matryoshka models and truncate natively, which lets us reuse
          // the existing float[768] column instead of migrating the vector store.
          .dimensions(EMBEDDING_DIMENSION as u32)
          .build()
          .map_err(|err| FlowyError::local_ai().with_context(err.to_string()))?;

        let response = client
          .embeddings()
          .create(request)
          .await
          .map_err(|err| FlowyError::local_ai().with_context(err.to_string()))?;

        let mut data = response.data;
        // The API does not guarantee ordering; `index` is authoritative.
        data.sort_by_key(|e| e.index);
        data.into_iter().map(|e| e.embedding).collect()
      },
    };

    ensure_dimensions(model, &embeddings)?;
    Ok(embeddings)
  }

  pub async fn chat(
    &self,
    model: &str,
    messages: &[Message],
    format: Option<&FormatType>,
    options: Option<&ModelOptions>,
  ) -> Result<GenerateResult, LLMError> {
    match self {
      AIClient::Ollama(ollama) => {
        let request = ollama_request(model, messages, format, options);
        let result = ollama.send_chat_messages(request).await?;
        let tokens = result.final_data.map(|final_data| {
          let prompt_tokens = final_data.prompt_eval_count as u32;
          let completion_tokens = final_data.eval_count as u32;
          TokenUsage {
            prompt_tokens,
            completion_tokens,
            total_tokens: prompt_tokens + completion_tokens,
          }
        });
        Ok(GenerateResult {
          tokens,
          generation: result.message.content,
        })
      },
      AIClient::OpenAI { client, .. } => {
        let request = openai_request(model, messages, format, false)?;
        let response = client.chat().create(request).await?;
        let generation = response
          .choices
          .into_iter()
          .next()
          .and_then(|c| c.message.content)
          .unwrap_or_default();
        let tokens = response.usage.map(|usage| TokenUsage {
          prompt_tokens: usage.prompt_tokens,
          completion_tokens: usage.completion_tokens,
          total_tokens: usage.total_tokens,
        });
        Ok(GenerateResult { tokens, generation })
      },
    }
  }

  pub async fn chat_stream(
    &self,
    model: &str,
    messages: &[Message],
    format: Option<&FormatType>,
    options: Option<&ModelOptions>,
  ) -> Result<Pin<Box<dyn Stream<Item = Result<StreamData, LLMError>> + Send>>, LLMError> {
    match self {
      AIClient::Ollama(ollama) => {
        let request = ollama_request(model, messages, format, options);
        let result = ollama.send_chat_messages_stream(request).await?;
        let stream = result.map(|data| match data {
          Ok(data) => Ok(StreamData::new(
            serde_json::to_value(&data).unwrap_or_default(),
            None,
            data.message.content,
          )),
          Err(_) => Err(ollama_rs::error::OllamaError::Other("Stream error".to_string()).into()),
        });
        Ok(Box::pin(stream))
      },
      AIClient::OpenAI { client, .. } => {
        let request = openai_request(model, messages, format, true)?;
        let stream = client.chat().create_stream(request).await?;
        let stream = stream.map(|chunk| match chunk {
          Ok(chunk) => {
            let content = chunk
              .choices
              .first()
              .and_then(|c| c.delta.content.clone())
              .unwrap_or_default();
            Ok(StreamData::new(
              serde_json::to_value(&chunk).unwrap_or_default(),
              None,
              content,
            ))
          },
          Err(err) => Err(LLMError::OpenAIError(err)),
        });
        Ok(Box::pin(stream))
      },
    }
  }
}

/// Rejects vectors the store cannot hold. Extracted from `embed` so the guard and its message are
/// testable without a live endpoint.
fn ensure_dimensions(model: &str, embeddings: &[Vec<f32>]) -> FlowyResult<()> {
  match embeddings
    .iter()
    .map(|e| e.len())
    .find(|n| *n != EMBEDDING_DIMENSION)
  {
    None => Ok(()),
    Some(actual) => Err(FlowyError::local_ai().with_context(format!(
      "embedding model '{model}' returned {actual}-dimensional vectors, but {required} are \
       required. Pick a model that supports {required} dimensions, or one that honours the \
       `dimensions` parameter (for example text-embedding-3-small).",
      model = model,
      actual = actual,
      required = EMBEDDING_DIMENSION,
    ))),
  }
}

fn ollama_request(
  model: &str,
  messages: &[Message],
  format: Option<&FormatType>,
  options: Option<&ModelOptions>,
) -> ChatMessageRequest {
  let mapped = messages.iter().map(|message| message.into()).collect();
  let mut request = ChatMessageRequest::new(model.to_string(), mapped);
  if let Some(options) = options {
    request = request.options(options.clone());
  }
  if let Some(format) = format {
    request = request.format(format.clone());
  }
  request
}

fn openai_request(
  model: &str,
  messages: &[Message],
  format: Option<&FormatType>,
  stream: bool,
) -> Result<async_openai::types::CreateChatCompletionRequest, LLMError> {
  let mut mapped = messages
    .iter()
    .map(openai_message)
    .collect::<Result<Vec<_>, LLMError>>()?;

  let mut builder = CreateChatCompletionRequestArgs::default();
  builder.model(model).stream(stream);

  if let Some(format) = format {
    // Ollama takes a JSON schema directly; the OpenAI-compatible equivalent that works across
    // gateways is `json_object` plus the schema in the prompt. Strict `json_schema` mode is
    // rejected by many compatible servers.
    builder.response_format(ResponseFormat::JsonObject);
    if let Ok(schema) = serde_json::to_value(format) {
      mapped.push(
        ChatCompletionRequestSystemMessageArgs::default()
          .content(format!(
            "Respond with a single JSON object matching this JSON Schema. \
             Output JSON only, with no markdown fences or commentary.\n{}",
            schema
          ))
          .build()?
          .into(),
      );
    }
  }

  builder.messages(mapped);
  Ok(builder.build()?)
}

#[cfg(test)]
mod tests {
  use super::*;
  use crate::local_ai::controller::LocalAISetting;

  /// Settings written before OpenAI-compatible support existed must still load, otherwise every
  /// existing install silently resets to defaults on upgrade.
  #[test]
  fn settings_stored_before_provider_support_still_load() {
    let stored = r#"{"ollama_server_url":"http://localhost:11434",
                     "chat_model_name":"llama3.1:latest",
                     "embedding_model_name":"nomic-embed-text:latest"}"#;

    let setting: LocalAISetting = serde_json::from_str(stored).unwrap();
    assert_eq!(setting.provider, AIProvider::Ollama);
    assert!(setting.api_key.is_empty());
    assert_eq!(setting.ollama_server_url, "http://localhost:11434");
    assert_eq!(setting.chat_model_name, "llama3.1:latest");
  }

  #[test]
  fn client_identity_tracks_provider_url_and_key() {
    let client = AIClient::new(AIProvider::OpenAI, "https://api.openai.com/v1", "k1").unwrap();

    // A trailing slash is the same endpoint and must not force a reload.
    assert!(client.matches(AIProvider::OpenAI, "https://api.openai.com/v1/", "k1"));
    // A rotated key must force a reload, or the old key keeps being used.
    assert!(!client.matches(AIProvider::OpenAI, "https://api.openai.com/v1", "k2"));
    assert!(!client.matches(AIProvider::Ollama, "https://api.openai.com/v1", "k1"));
  }

  /// Same URL, different protocol: these are not interchangeable clients.
  #[test]
  fn ollama_and_openai_at_one_url_are_distinct() {
    let ollama = AIClient::new(AIProvider::Ollama, "http://localhost:11434", "").unwrap();
    let openai = AIClient::new(AIProvider::OpenAI, "http://localhost:11434", "").unwrap();
    assert!(!ollama.same_as(&openai));
    assert!(!openai.same_as(&ollama));
  }

  /// Ollama takes a JSON schema natively; the OpenAI path has to carry it in the prompt instead.
  #[test]
  fn structured_output_becomes_json_mode_plus_schema_message() {
    let messages = vec![Message::new_human_message("hi")];
    let format = FormatType::Json;

    let plain = openai_request("gpt-4o", &messages, None, false).unwrap();
    assert_eq!(plain.messages.len(), 1);
    assert!(plain.response_format.is_none());

    let structured = openai_request("gpt-4o", &messages, Some(&format), false).unwrap();
    assert_eq!(structured.messages.len(), 2);
    assert!(matches!(
      structured.response_format,
      Some(ResponseFormat::JsonObject)
    ));
  }

  #[test]
  fn dimension_guard_accepts_correct_size_and_rejects_others() {
    assert!(ensure_dimensions("m", &[vec![0.0; EMBEDDING_DIMENSION]]).is_ok());
    assert!(ensure_dimensions("m", &[]).is_ok());
    // A single bad vector in an otherwise valid batch must still be caught.
    let mixed = vec![vec![0.0; EMBEDDING_DIMENSION], vec![0.0; 1536]];
    assert!(ensure_dimensions("m", &mixed).is_err());
  }

  /// The message must report the *required* dimension, not echo the model name back. A previous
  /// revision used `{0}`, which silently resolved to the model argument.
  #[test]
  fn dimension_error_reports_required_size_not_model_name() {
    let err = ensure_dimensions("text-embedding-3-large", &[vec![0.0; 3072]]).unwrap_err();
    let msg = err.to_string();

    assert!(msg.contains("returned 3072-dimensional"), "{msg}");
    assert!(msg.contains("but 768 are required"), "{msg}");
    assert!(msg.contains("supports 768 dimensions"), "{msg}");
    assert!(
      !msg.contains("supports text-embedding-3-large dimensions"),
      "model name leaked into the dimension slot: {msg}"
    );
  }

  #[test]
  fn message_roles_map_to_openai_roles() {
    let mapped = openai_message(&Message::new_system_message("s")).unwrap();
    assert!(matches!(
      mapped,
      ChatCompletionRequestMessage::System(_)
    ));
    let mapped = openai_message(&Message::new_ai_message("a")).unwrap();
    assert!(matches!(
      mapped,
      ChatCompletionRequestMessage::Assistant(_)
    ));
    let mapped = openai_message(&Message::new_human_message("h")).unwrap();
    assert!(matches!(mapped, ChatCompletionRequestMessage::User(_)));
  }
}

fn openai_message(message: &Message) -> Result<ChatCompletionRequestMessage, LLMError> {
  let content = message.content.clone();
  Ok(match message.message_type {
    MessageType::SystemMessage => ChatCompletionRequestSystemMessageArgs::default()
      .content(content)
      .build()?
      .into(),
    MessageType::AIMessage => ChatCompletionRequestAssistantMessageArgs::default()
      .content(content)
      .build()?
      .into(),
    // Tool results carry no tool_call_id here, so surface them as user turns rather than dropping.
    MessageType::HumanMessage | MessageType::ToolMessage => {
      ChatCompletionRequestUserMessageArgs::default()
        .content(content)
        .build()?
        .into()
    },
  })
}

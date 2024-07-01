use anyhow::anyhow;
use bytes::Bytes;
use flowy_error::FlowyError;
use flowy_sidecar::core::parser::{DefaultResponseParser, ResponseParser};
use flowy_sidecar::core::plugin::Plugin;
use flowy_sidecar::error::{RemoteError, SidecarError};
use serde_json::json;
use serde_json::Value as JsonValue;
use std::sync::Weak;
use tokio_stream::wrappers::ReceiverStream;
use tracing::instrument;

pub struct ChatPluginOperation {
  plugin: Weak<Plugin>,
}

impl ChatPluginOperation {
  pub fn new(plugin: Weak<Plugin>) -> Self {
    ChatPluginOperation { plugin }
  }

  fn get_plugin(&self) -> Result<std::sync::Arc<Plugin>, SidecarError> {
    self
      .plugin
      .upgrade()
      .ok_or_else(|| SidecarError::Internal(anyhow!("Plugin is dropped")))
  }

  async fn send_request<T: ResponseParser>(
    &self,
    method: &str,
    params: JsonValue,
  ) -> Result<T::ValueType, SidecarError> {
    let plugin = self.get_plugin()?;
    let mut request = json!({ "method": method });
    request
      .as_object_mut()
      .unwrap()
      .extend(params.as_object().unwrap().clone());
    plugin.async_request::<T>("handle", &request).await
  }

  pub async fn create_chat(&self, chat_id: &str) -> Result<(), SidecarError> {
    self
      .send_request::<DefaultResponseParser>("create_chat", json!({ "chat_id": chat_id }))
      .await
  }

  pub async fn close_chat(&self, chat_id: &str) -> Result<(), SidecarError> {
    self
      .send_request::<DefaultResponseParser>("close_chat", json!({ "chat_id": chat_id }))
      .await
  }

  pub async fn send_message(&self, chat_id: &str, message: &str) -> Result<String, SidecarError> {
    self
      .send_request::<ChatResponseParser>(
        "answer",
        json!({ "chat_id": chat_id, "params": { "content": message } }),
      )
      .await
  }

  #[instrument(level = "debug", skip(self), err)]
  pub async fn stream_message(
    &self,
    chat_id: &str,
    message: &str,
  ) -> Result<ReceiverStream<Result<Bytes, SidecarError>>, FlowyError> {
    let plugin = self
      .get_plugin()
      .map_err(|err| FlowyError::internal().with_context(err.to_string()))?;
    let params = json!({
        "chat_id": chat_id,
        "method": "stream_answer",
        "params": { "content": message }
    });
    plugin
      .stream_request::<ChatStreamResponseParser>("handle", &params)
      .map_err(|err| FlowyError::internal().with_context(err.to_string()))
  }

  pub async fn get_related_questions(&self, chat_id: &str) -> Result<Vec<JsonValue>, SidecarError> {
    self
      .send_request::<ChatRelatedQuestionsResponseParser>(
        "related_question",
        json!({ "chat_id": chat_id }),
      )
      .await
  }
}

pub struct ChatResponseParser;
impl ResponseParser for ChatResponseParser {
  type ValueType = String;

  fn parse_json(json: JsonValue) -> Result<Self::ValueType, RemoteError> {
    json
      .get("data")
      .and_then(|data| data.as_str())
      .map(String::from)
      .ok_or(RemoteError::ParseResponse(json))
  }
}

pub struct ChatStreamResponseParser;
impl ResponseParser for ChatStreamResponseParser {
  type ValueType = Bytes;

  fn parse_json(json: JsonValue) -> Result<Self::ValueType, RemoteError> {
    json
      .as_str()
      .map(|message| Bytes::from(message.to_string()))
      .ok_or(RemoteError::ParseResponse(json))
  }
}

pub struct ChatRelatedQuestionsResponseParser;
impl ResponseParser for ChatRelatedQuestionsResponseParser {
  type ValueType = Vec<JsonValue>;

  fn parse_json(json: JsonValue) -> Result<Self::ValueType, RemoteError> {
    json
      .get("data")
      .and_then(|data| data.as_array())
      .cloned()
      .ok_or(RemoteError::ParseResponse(json))
  }
}

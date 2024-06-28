use anyhow::anyhow;
use flowy_error::FlowyError;
use flowy_sidecar::core::parser::ResponseParser;
use flowy_sidecar::core::plugin::{Plugin, PluginId};
use flowy_sidecar::error::{RemoteError, SidecarError};
use serde_json::json;
use serde_json::Value as JsonValue;
use std::sync::Weak;
use tokio_stream::wrappers::ReceiverStream;

pub struct ChatPluginOperation {
  plugin: Weak<Plugin>,
}

impl ChatPluginOperation {
  pub fn new(plugin: Weak<Plugin>) -> Self {
    ChatPluginOperation { plugin }
  }

  pub async fn send_message(
    &self,
    chat_id: &str,
    _plugin_id: PluginId,
    message: &str,
  ) -> Result<String, SidecarError> {
    let plugin = self
      .plugin
      .upgrade()
      .ok_or(SidecarError::Internal(anyhow!("Plugin is dropped")))?;

    let params = json!({"chat_id": chat_id, "method": "answer", "params": {"content": message}});
    let resp = plugin
      .async_request::<ChatResponseParser>("handle", &params)
      .await?;
    Ok(resp)
  }

  pub async fn stream_message(
    &self,
    chat_id: &str,
    _plugin_id: PluginId,
    message: &str,
  ) -> Result<ReceiverStream<Result<String, SidecarError>>, FlowyError> {
    let plugin = self
      .plugin
      .upgrade()
      .ok_or(FlowyError::internal().with_context("Plugin is dropped"))?;

    let params =
      json!({"chat_id": chat_id, "method": "stream_answer", "params": {"content": message}});
    let stream = plugin
      .stream_request::<ChatStreamResponseParser>("handle", &params)
      .map_err(|err| FlowyError::internal().with_context(err.to_string()))?;
    Ok(stream)
  }

  pub async fn get_related_questions(
    &self,
    chat_id: &str,
  ) -> Result<Vec<serde_json::Value>, SidecarError> {
    let plugin = self
      .plugin
      .upgrade()
      .ok_or(SidecarError::Internal(anyhow!("Plugin is dropped")))?;

    let params = json!({"chat_id": chat_id, "method": "related_question"});
    let resp = plugin
      .async_request::<ChatRelatedQuestionsResponseParser>("handle", &params)
      .await?;
    Ok(resp)
  }
}

pub struct ChatResponseParser;
impl ResponseParser for ChatResponseParser {
  type ValueType = String;

  fn parse_json(json: JsonValue) -> Result<Self::ValueType, RemoteError> {
    if json.is_object() {
      if let Some(data) = json.get("data") {
        if let Some(message) = data.as_str() {
          return Ok(message.to_string());
        }
      }
    }
    return Err(RemoteError::ParseResponse(json));
  }
}

pub struct ChatStreamResponseParser;
impl ResponseParser for ChatStreamResponseParser {
  type ValueType = String;

  fn parse_json(json: JsonValue) -> Result<Self::ValueType, RemoteError> {
    if let Some(message) = json.as_str() {
      return Ok(message.to_string());
    }
    return Err(RemoteError::ParseResponse(json));
  }
}

pub struct ChatRelatedQuestionsResponseParser;
impl ResponseParser for ChatRelatedQuestionsResponseParser {
  type ValueType = Vec<JsonValue>;

  fn parse_json(json: JsonValue) -> Result<Self::ValueType, RemoteError> {
    if json.is_object() {
      if let Some(data) = json.get("data") {
        if let Some(values) = data.as_array() {
          return Ok(values.clone());
        }
      }
    }
    return Err(RemoteError::ParseResponse(json));
  }
}

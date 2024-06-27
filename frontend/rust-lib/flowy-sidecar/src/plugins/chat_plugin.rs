use crate::core::parser::{
  ChatRelatedQuestionsResponseParser, ChatResponseParser, ChatStreamResponseParser,
};
use crate::core::plugin::{Plugin, PluginId};
use crate::error::SidecarError;
use anyhow::anyhow;
use serde_json::json;
use std::sync::Weak;
use tokio_stream::wrappers::ReceiverStream;
use tokio_stream::Stream;

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
  ) -> Result<ReceiverStream<Result<String, SidecarError>>, SidecarError> {
    let plugin = self
      .plugin
      .upgrade()
      .ok_or(SidecarError::Internal(anyhow!("Plugin is dropped")))?;

    let params =
      json!({"chat_id": chat_id, "method": "stream_answer", "params": {"content": message}});
    plugin.stream_request::<ChatStreamResponseParser>("handle", &params)
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

use crate::ai_manager::AIUserService;
use crate::entities::{ChatStatePB, ModelTypePB};
use crate::local_ai::local_llm_chat::LocalAIController;
use crate::notification::{make_notification, ChatNotification, APPFLOWY_AI_NOTIFICATION_KEY};
use crate::persistence::{select_single_message, ChatMessageTable};
use appflowy_plugin::error::PluginError;
use std::collections::HashMap;

use flowy_ai_pub::cloud::{
  ChatCloudService, ChatMessage, ChatMessageMetadata, ChatMessageType, CompletionType,
  CreateTextChatContext, LocalAIConfig, MessageCursor, RelatedQuestion, RepeatedChatMessage,
  RepeatedRelatedQuestion, StreamAnswer, StreamComplete,
};
use flowy_error::{FlowyError, FlowyResult};
use futures::{stream, Sink, StreamExt, TryStreamExt};
use lib_infra::async_trait::async_trait;

use crate::local_ai::stream_util::QuestionStream;
use crate::stream_message::StreamMessage;
use flowy_storage_pub::storage::StorageService;
use futures_util::SinkExt;
use serde_json::{json, Value};
use std::path::Path;
use std::sync::{Arc, Weak};
use tracing::trace;

pub struct AICloudServiceMiddleware {
  cloud_service: Arc<dyn ChatCloudService>,
  user_service: Arc<dyn AIUserService>,
  local_llm_controller: Arc<LocalAIController>,
  storage_service: Weak<dyn StorageService>,
}

impl AICloudServiceMiddleware {
  pub fn new(
    user_service: Arc<dyn AIUserService>,
    cloud_service: Arc<dyn ChatCloudService>,
    local_llm_controller: Arc<LocalAIController>,
    storage_service: Weak<dyn StorageService>,
  ) -> Self {
    Self {
      user_service,
      cloud_service,
      local_llm_controller,
      storage_service,
    }
  }

  pub fn is_local_ai_enabled(&self) -> bool {
    self.local_llm_controller.is_enabled()
  }

  pub async fn index_message_metadata(
    &self,
    chat_id: &str,
    metadata_list: &[ChatMessageMetadata],
    index_process_sink: &mut (impl Sink<String> + Unpin),
  ) -> Result<(), FlowyError> {
    if metadata_list.is_empty() {
      return Ok(());
    }
    if self.is_local_ai_enabled() {
      let _ = index_process_sink
        .send(StreamMessage::IndexStart.to_string())
        .await;

      self
        .local_llm_controller
        .index_message_metadata(chat_id, metadata_list, index_process_sink)
        .await?;
      let _ = index_process_sink
        .send(StreamMessage::IndexEnd.to_string())
        .await;
    } else if let Some(_storage_service) = self.storage_service.upgrade() {
      //
    }
    Ok(())
  }

  fn get_message_record(&self, message_id: i64) -> FlowyResult<ChatMessageTable> {
    let uid = self.user_service.user_id()?;
    let conn = self.user_service.sqlite_connection(uid)?;
    let row = select_single_message(conn, message_id)?.ok_or_else(|| {
      FlowyError::record_not_found().with_context(format!("Message not found: {}", message_id))
    })?;

    Ok(row)
  }

  fn handle_plugin_error(&self, err: PluginError) {
    if matches!(
      err,
      PluginError::PluginNotConnected | PluginError::PeerDisconnect
    ) {
      make_notification(
        APPFLOWY_AI_NOTIFICATION_KEY,
        ChatNotification::UpdateChatPluginState,
      )
      .payload(ChatStatePB {
        model_type: ModelTypePB::LocalAI,
        available: false,
      })
      .send();
    }
  }
}

#[async_trait]
impl ChatCloudService for AICloudServiceMiddleware {
  async fn create_chat(
    &self,
    uid: &i64,
    workspace_id: &str,
    chat_id: &str,
  ) -> Result<(), FlowyError> {
    self
      .cloud_service
      .create_chat(uid, workspace_id, chat_id)
      .await
  }

  async fn create_question(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message: &str,
    message_type: ChatMessageType,
    metadata: &[ChatMessageMetadata],
  ) -> Result<ChatMessage, FlowyError> {
    self
      .cloud_service
      .create_question(workspace_id, chat_id, message, message_type, metadata)
      .await
  }

  async fn create_answer(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message: &str,
    question_id: i64,
    metadata: Option<serde_json::Value>,
  ) -> Result<ChatMessage, FlowyError> {
    self
      .cloud_service
      .create_answer(workspace_id, chat_id, message, question_id, metadata)
      .await
  }

  async fn stream_answer(
    &self,
    workspace_id: &str,
    chat_id: &str,
    question_id: i64,
  ) -> Result<StreamAnswer, FlowyError> {
    if self.local_llm_controller.is_running() {
      let row = self.get_message_record(question_id)?;
      match self
        .local_llm_controller
        .stream_question(chat_id, &row.content, json!([]))
        .await
      {
        Ok(stream) => Ok(QuestionStream::new(stream).boxed()),
        Err(err) => {
          self.handle_plugin_error(err);
          Ok(stream::once(async { Err(FlowyError::local_ai_unavailable()) }).boxed())
        },
      }
    } else {
      self
        .cloud_service
        .stream_answer(workspace_id, chat_id, question_id)
        .await
    }
  }

  async fn get_answer(
    &self,
    workspace_id: &str,
    chat_id: &str,
    question_message_id: i64,
  ) -> Result<ChatMessage, FlowyError> {
    if self.local_llm_controller.is_running() {
      let content = self.get_message_record(question_message_id)?.content;
      match self
        .local_llm_controller
        .ask_question(chat_id, &content)
        .await
      {
        Ok(answer) => {
          // TODO(nathan): metadata
          let message = self
            .cloud_service
            .create_answer(workspace_id, chat_id, &answer, question_message_id, None)
            .await?;
          Ok(message)
        },
        Err(err) => {
          self.handle_plugin_error(err);
          Err(FlowyError::local_ai_unavailable())
        },
      }
    } else {
      self
        .cloud_service
        .get_answer(workspace_id, chat_id, question_message_id)
        .await
    }
  }

  async fn get_chat_messages(
    &self,
    workspace_id: &str,
    chat_id: &str,
    offset: MessageCursor,
    limit: u64,
  ) -> Result<RepeatedChatMessage, FlowyError> {
    self
      .cloud_service
      .get_chat_messages(workspace_id, chat_id, offset, limit)
      .await
  }

  async fn get_related_message(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message_id: i64,
  ) -> Result<RepeatedRelatedQuestion, FlowyError> {
    if self.local_llm_controller.is_running() {
      let questions = self
        .local_llm_controller
        .get_related_question(chat_id)
        .await
        .map_err(|err| FlowyError::local_ai().with_context(err))?;
      trace!("LocalAI related questions: {:?}", questions);

      let items = questions
        .into_iter()
        .map(|content| RelatedQuestion {
          content,
          metadata: None,
        })
        .collect::<Vec<_>>();

      Ok(RepeatedRelatedQuestion { message_id, items })
    } else {
      self
        .cloud_service
        .get_related_message(workspace_id, chat_id, message_id)
        .await
    }
  }

  async fn stream_complete(
    &self,
    workspace_id: &str,
    text: &str,
    complete_type: CompletionType,
  ) -> Result<StreamComplete, FlowyError> {
    if self.local_llm_controller.is_running() {
      match self
        .local_llm_controller
        .complete_text(text, complete_type as u8)
        .await
      {
        Ok(stream) => Ok(
          stream
            .map_err(|err| FlowyError::local_ai().with_context(err))
            .boxed(),
        ),
        Err(err) => {
          self.handle_plugin_error(err);
          Ok(stream::once(async { Err(FlowyError::local_ai_unavailable()) }).boxed())
        },
      }
    } else {
      self
        .cloud_service
        .stream_complete(workspace_id, text, complete_type)
        .await
    }
  }

  async fn index_file(
    &self,
    workspace_id: &str,
    file_path: &Path,
    chat_id: &str,
    metadata: Option<HashMap<String, Value>>,
  ) -> Result<(), FlowyError> {
    if self.local_llm_controller.is_running() {
      self
        .local_llm_controller
        .index_file(chat_id, Some(file_path.to_path_buf()), None, metadata)
        .await
        .map_err(|err| FlowyError::local_ai().with_context(err))?;
      Ok(())
    } else {
      self
        .cloud_service
        .index_file(workspace_id, file_path, chat_id, metadata)
        .await
    }
  }

  async fn get_local_ai_config(&self, workspace_id: &str) -> Result<LocalAIConfig, FlowyError> {
    self.cloud_service.get_local_ai_config(workspace_id).await
  }

  async fn create_chat_context(
    &self,
    workspace_id: &str,
    chat_context: CreateTextChatContext,
  ) -> Result<(), FlowyError> {
    if self.local_llm_controller.is_running() {
      // TODO(nathan): support offline ai context
      Ok(())
    } else {
      self
        .cloud_service
        .create_chat_context(workspace_id, chat_context)
        .await
    }
  }
}

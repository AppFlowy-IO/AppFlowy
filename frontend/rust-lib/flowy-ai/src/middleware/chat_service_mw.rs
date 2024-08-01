use crate::ai_manager::AIUserService;
use crate::entities::{ChatStatePB, ModelTypePB};
use crate::local_ai::local_llm_chat::LocalAIController;
use crate::notification::{make_notification, ChatNotification, APPFLOWY_AI_NOTIFICATION_KEY};
use crate::persistence::select_single_message;
use appflowy_plugin::error::PluginError;

use flowy_ai_pub::cloud::{
  ChatCloudService, ChatMessage, ChatMessageType, CompletionType, LocalAIConfig, MessageCursor,
  RelatedQuestion, RepeatedChatMessage, RepeatedRelatedQuestion, StreamAnswer, StreamComplete,
};
use flowy_error::{FlowyError, FlowyResult};
use futures::{stream, StreamExt, TryStreamExt};
use lib_infra::async_trait::async_trait;
use lib_infra::future::FutureResult;

use std::path::PathBuf;
use std::sync::Arc;

pub struct AICloudServiceMiddleware {
  cloud_service: Arc<dyn ChatCloudService>,
  user_service: Arc<dyn AIUserService>,
  local_llm_controller: Arc<LocalAIController>,
}

impl AICloudServiceMiddleware {
  pub fn new(
    user_service: Arc<dyn AIUserService>,
    cloud_service: Arc<dyn ChatCloudService>,
    local_llm_controller: Arc<LocalAIController>,
  ) -> Self {
    Self {
      user_service,
      cloud_service,
      local_llm_controller,
    }
  }

  fn get_message_content(&self, message_id: i64) -> FlowyResult<String> {
    let uid = self.user_service.user_id()?;
    let conn = self.user_service.sqlite_connection(uid)?;
    let content = select_single_message(conn, message_id)?
      .map(|data| data.content)
      .ok_or_else(|| {
        FlowyError::record_not_found().with_context(format!("Message not found: {}", message_id))
      })?;

    Ok(content)
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
  fn create_chat(
    &self,
    uid: &i64,
    workspace_id: &str,
    chat_id: &str,
  ) -> FutureResult<(), FlowyError> {
    self.cloud_service.create_chat(uid, workspace_id, chat_id)
  }

  fn save_question(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message: &str,
    message_type: ChatMessageType,
  ) -> FutureResult<ChatMessage, FlowyError> {
    self
      .cloud_service
      .save_question(workspace_id, chat_id, message, message_type)
  }

  fn save_answer(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message: &str,
    question_id: i64,
  ) -> FutureResult<ChatMessage, FlowyError> {
    self
      .cloud_service
      .save_answer(workspace_id, chat_id, message, question_id)
  }

  async fn ask_question(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message_id: i64,
  ) -> Result<StreamAnswer, FlowyError> {
    if self.local_llm_controller.is_running() {
      let content = self.get_message_content(message_id)?;
      match self
        .local_llm_controller
        .stream_question(chat_id, &content)
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
        .ask_question(workspace_id, chat_id, message_id)
        .await
    }
  }

  async fn generate_answer(
    &self,
    workspace_id: &str,
    chat_id: &str,
    question_message_id: i64,
  ) -> Result<ChatMessage, FlowyError> {
    if self.local_llm_controller.is_running() {
      let content = self.get_message_content(question_message_id)?;
      match self
        .local_llm_controller
        .ask_question(chat_id, &content)
        .await
      {
        Ok(answer) => {
          let message = self
            .cloud_service
            .save_answer(workspace_id, chat_id, &answer, question_message_id)
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
        .generate_answer(workspace_id, chat_id, question_message_id)
        .await
    }
  }

  fn get_chat_messages(
    &self,
    workspace_id: &str,
    chat_id: &str,
    offset: MessageCursor,
    limit: u64,
  ) -> FutureResult<RepeatedChatMessage, FlowyError> {
    self
      .cloud_service
      .get_chat_messages(workspace_id, chat_id, offset, limit)
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
        .map_err(|err| FlowyError::local_ai().with_context(err))?
        .into_iter()
        .map(|content| RelatedQuestion {
          content,
          metadata: None,
        })
        .collect::<Vec<_>>();

      Ok(RepeatedRelatedQuestion {
        message_id,
        items: questions,
      })
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
    file_path: PathBuf,
    chat_id: &str,
  ) -> Result<(), FlowyError> {
    if self.local_llm_controller.is_running() {
      self
        .local_llm_controller
        .index_file(chat_id, file_path)
        .await
        .map_err(|err| FlowyError::local_ai().with_context(err))?;
      Ok(())
    } else {
      self
        .cloud_service
        .index_file(workspace_id, file_path, chat_id)
        .await
    }
  }

  async fn get_local_ai_config(&self, workspace_id: &str) -> Result<LocalAIConfig, FlowyError> {
    self.cloud_service.get_local_ai_config(workspace_id).await
  }
}

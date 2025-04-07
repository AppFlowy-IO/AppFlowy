use crate::ai_manager::AIUserService;
use crate::entities::{ChatStatePB, ModelTypePB};
use crate::local_ai::controller::LocalAIController;
use crate::notification::{
  chat_notification_builder, ChatNotification, APPFLOWY_AI_NOTIFICATION_KEY,
};
use crate::persistence::{select_single_message, ChatMessageTable};
use af_plugin::error::PluginError;
use std::collections::HashMap;

use flowy_ai_pub::cloud::{
  AIModel, AppErrorCode, AppResponseError, ChatCloudService, ChatMessage, ChatMessageMetadata,
  ChatMessageType, ChatSettings, CompleteTextParams, CompletionStream, LocalAIConfig,
  MessageCursor, ModelList, RelatedQuestion, RepeatedChatMessage, RepeatedRelatedQuestion,
  ResponseFormat, StreamAnswer, StreamComplete, SubscriptionPlan, UpdateChatParams,
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
use tracing::{info, trace};
use uuid::Uuid;

pub struct AICloudServiceMiddleware {
  cloud_service: Arc<dyn ChatCloudService>,
  user_service: Arc<dyn AIUserService>,
  local_ai: Arc<LocalAIController>,
  storage_service: Weak<dyn StorageService>,
}

impl AICloudServiceMiddleware {
  pub fn new(
    user_service: Arc<dyn AIUserService>,
    cloud_service: Arc<dyn ChatCloudService>,
    local_ai: Arc<LocalAIController>,
    storage_service: Weak<dyn StorageService>,
  ) -> Self {
    Self {
      user_service,
      cloud_service,
      local_ai,
      storage_service,
    }
  }

  pub fn is_local_ai_enabled(&self) -> bool {
    self.local_ai.is_enabled()
  }

  pub async fn index_message_metadata(
    &self,
    chat_id: &Uuid,
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
      let result = self
        .local_ai
        .index_message_metadata(chat_id, metadata_list, index_process_sink)
        .await;
      let _ = index_process_sink
        .send(StreamMessage::IndexEnd.to_string())
        .await;

      result?
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
      chat_notification_builder(
        APPFLOWY_AI_NOTIFICATION_KEY,
        ChatNotification::UpdateLocalAIState,
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
    workspace_id: &Uuid,
    chat_id: &Uuid,
    rag_ids: Vec<Uuid>,
  ) -> Result<(), FlowyError> {
    self
      .cloud_service
      .create_chat(uid, workspace_id, chat_id, rag_ids)
      .await
  }

  async fn create_question(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
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
    workspace_id: &Uuid,
    chat_id: &Uuid,
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
    workspace_id: &Uuid,
    chat_id: &Uuid,
    message_id: i64,
    format: ResponseFormat,
    ai_model: Option<AIModel>,
  ) -> Result<StreamAnswer, FlowyError> {
    let use_local_ai = match &ai_model {
      None => false,
      Some(model) => model.is_local,
    };

    info!("stream_answer use model: {:?}", ai_model);
    if use_local_ai {
      if self.local_ai.is_running() {
        let row = self.get_message_record(message_id)?;
        match self
          .local_ai
          .stream_question(
            &chat_id.to_string(),
            &row.content,
            Some(json!(format)),
            json!({}),
          )
          .await
        {
          Ok(stream) => Ok(QuestionStream::new(stream).boxed()),
          Err(err) => {
            self.handle_plugin_error(err);
            Ok(stream::once(async { Err(FlowyError::local_ai_unavailable()) }).boxed())
          },
        }
      } else if self.local_ai.is_enabled() {
        Err(FlowyError::local_ai_not_ready())
      } else {
        Err(FlowyError::local_ai_disabled())
      }
    } else {
      self
        .cloud_service
        .stream_answer(workspace_id, chat_id, message_id, format, ai_model)
        .await
    }
  }

  async fn get_answer(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    question_message_id: i64,
  ) -> Result<ChatMessage, FlowyError> {
    if self.local_ai.is_running() {
      let content = self.get_message_record(question_message_id)?.content;
      match self
        .local_ai
        .ask_question(&chat_id.to_string(), &content)
        .await
      {
        Ok(answer) => {
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
    workspace_id: &Uuid,
    chat_id: &Uuid,
    offset: MessageCursor,
    limit: u64,
  ) -> Result<RepeatedChatMessage, FlowyError> {
    self
      .cloud_service
      .get_chat_messages(workspace_id, chat_id, offset, limit)
      .await
  }

  async fn get_question_from_answer_id(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    answer_message_id: i64,
  ) -> Result<ChatMessage, FlowyError> {
    self
      .cloud_service
      .get_question_from_answer_id(workspace_id, chat_id, answer_message_id)
      .await
  }

  async fn get_related_message(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    message_id: i64,
  ) -> Result<RepeatedRelatedQuestion, FlowyError> {
    if self.local_ai.is_running() {
      let questions = self
        .local_ai
        .get_related_question(&chat_id.to_string())
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
    workspace_id: &Uuid,
    params: CompleteTextParams,
    ai_model: Option<AIModel>,
  ) -> Result<StreamComplete, FlowyError> {
    let use_local_ai = match &ai_model {
      None => false,
      Some(model) => model.is_local,
    };

    info!("stream_complete use custom model: {:?}", ai_model);
    if use_local_ai {
      if self.local_ai.is_running() {
        match self
          .local_ai
          .complete_text_v2(
            &params.text,
            params.completion_type.unwrap() as u8,
            Some(json!(params.format)),
            Some(json!(params.metadata)),
          )
          .await
        {
          Ok(stream) => Ok(
            CompletionStream::new(
              stream.map_err(|err| AppResponseError::new(AppErrorCode::Internal, err.to_string())),
            )
            .map_err(FlowyError::from)
            .boxed(),
          ),
          Err(err) => {
            self.handle_plugin_error(err);
            Ok(stream::once(async { Err(FlowyError::local_ai_unavailable()) }).boxed())
          },
        }
      } else if self.local_ai.is_enabled() {
        Err(FlowyError::local_ai_not_ready())
      } else {
        Err(FlowyError::local_ai_disabled())
      }
    } else {
      self
        .cloud_service
        .stream_complete(workspace_id, params, ai_model)
        .await
    }
  }

  async fn embed_file(
    &self,
    workspace_id: &Uuid,
    file_path: &Path,
    chat_id: &Uuid,
    metadata: Option<HashMap<String, Value>>,
  ) -> Result<(), FlowyError> {
    if self.local_ai.is_running() {
      self
        .local_ai
        .embed_file(&chat_id.to_string(), file_path.to_path_buf(), metadata)
        .await
        .map_err(|err| FlowyError::local_ai().with_context(err))?;
      Ok(())
    } else {
      self
        .cloud_service
        .embed_file(workspace_id, file_path, chat_id, metadata)
        .await
    }
  }

  async fn get_local_ai_config(&self, workspace_id: &Uuid) -> Result<LocalAIConfig, FlowyError> {
    self.cloud_service.get_local_ai_config(workspace_id).await
  }

  async fn get_workspace_plan(
    &self,
    workspace_id: &Uuid,
  ) -> Result<Vec<SubscriptionPlan>, FlowyError> {
    self.cloud_service.get_workspace_plan(workspace_id).await
  }

  async fn get_chat_settings(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
  ) -> Result<ChatSettings, FlowyError> {
    self
      .cloud_service
      .get_chat_settings(workspace_id, chat_id)
      .await
  }

  async fn update_chat_settings(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    params: UpdateChatParams,
  ) -> Result<(), FlowyError> {
    self
      .cloud_service
      .update_chat_settings(workspace_id, chat_id, params)
      .await
  }

  async fn get_available_models(&self, workspace_id: &Uuid) -> Result<ModelList, FlowyError> {
    self.cloud_service.get_available_models(workspace_id).await
  }

  async fn get_workspace_default_model(&self, workspace_id: &Uuid) -> Result<String, FlowyError> {
    self
      .cloud_service
      .get_workspace_default_model(workspace_id)
      .await
  }
}

use crate::chat_manager::ChatUserService;
use crate::local_ai::llm_controller::{LocalChatLLMController, LocalLLMSetting};
use crate::persistence::select_single_message;
use flowy_chat_pub::cloud::{
  ChatCloudService, ChatMessage, ChatMessageType, CompletionType, MessageCursor,
  RepeatedChatMessage, RepeatedRelatedQuestion, StreamAnswer, StreamComplete,
};
use flowy_error::{FlowyError, FlowyResult};
use futures::{StreamExt, TryStreamExt};
use lib_infra::async_trait::async_trait;
use lib_infra::future::FutureResult;
use parking_lot::RwLock;
use std::sync::Arc;
use tracing::{error, info, trace};

#[derive(Debug, Clone)]
pub enum LLMStatus {
  Loading,
  FinishLoading,
}

pub struct ChatService {
  pub cloud_service: Arc<dyn ChatCloudService>,
  user_service: Arc<dyn ChatUserService>,
  local_llm_ctrl: Arc<LocalChatLLMController>,
  local_llm_setting: Arc<RwLock<LocalLLMSetting>>,
  llm_status: tokio::sync::broadcast::Sender<LLMStatus>,
}

impl ChatService {
  pub fn new(
    user_service: Arc<dyn ChatUserService>,
    cloud_service: Arc<dyn ChatCloudService>,
    local_llm_ctrl: Arc<LocalChatLLMController>,
    local_llm_setting: LocalLLMSetting,
  ) -> Self {
    let (tx, rx) = tokio::sync::broadcast::channel(100);

    if local_llm_setting.enabled {
      setup_local_ai(&local_llm_setting, local_llm_ctrl.clone());
    }

    Self {
      user_service,
      cloud_service,
      local_llm_ctrl,
      local_llm_setting: Arc::new(RwLock::new(local_llm_setting)),
      llm_status: tx,
    }
  }

  pub fn notify_open_chat(&self, chat_id: &str) {
    if self.local_llm_setting.read().enabled {
      let chat_id = chat_id.to_string();
      let weak_ctrl = Arc::downgrade(&self.local_llm_ctrl);
      tokio::spawn(async move {
        if let Some(ctrl) = weak_ctrl.upgrade() {
          if let Err(err) = ctrl.create_chat(&chat_id).await {
            error!("[Chat Plugin] failed to open chat: {:?}", err);
          }
        }
      });
    }
  }

  pub fn notify_close_chat(&self, chat_id: &str) {
    if self.local_llm_setting.read().enabled {
      let weak_ctrl = Arc::downgrade(&self.local_llm_ctrl);
      let chat_id = chat_id.to_string();
      tokio::spawn(async move {
        if let Some(ctrl) = weak_ctrl.upgrade() {
          if let Err(err) = ctrl.close_chat(&chat_id).await {
            error!("[Chat Plugin] failed to close chat: {:?}", err);
          }
        }
      });
    }
  }

  pub fn get_local_ai_setting(&self) -> LocalLLMSetting {
    self.local_llm_setting.read().clone()
  }

  pub fn update_local_ai_setting(&self, setting: LocalLLMSetting) -> FlowyResult<()> {
    setting.validate()?;

    setup_local_ai(&setting, self.local_llm_ctrl.clone());
    *self.local_llm_setting.write() = setting;
    Ok(())
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
}

#[async_trait]
impl ChatCloudService for ChatService {
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
    if self.local_llm_setting.read().enabled {
      let content = self.get_message_content(message_id)?;
      let stream = self
        .local_llm_ctrl
        .ask_question(chat_id, &content)
        .await?
        .map_err(FlowyError::from);
      Ok(stream.boxed())
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
    if self.local_llm_setting.read().enabled {
      let content = self.get_message_content(question_message_id)?;
      let _answer = self
        .local_llm_ctrl
        .generate_answer(chat_id, &content)
        .await?;
      todo!()
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

  fn get_related_message(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message_id: i64,
  ) -> FutureResult<RepeatedRelatedQuestion, FlowyError> {
    if self.local_llm_setting.read().enabled {
      FutureResult::new(async move {
        Ok(RepeatedRelatedQuestion {
          message_id,
          items: vec![],
        })
      })
    } else {
      self
        .cloud_service
        .get_related_message(workspace_id, chat_id, message_id)
    }
  }

  async fn stream_complete(
    &self,
    workspace_id: &str,
    text: &str,
    complete_type: CompletionType,
  ) -> Result<StreamComplete, FlowyError> {
    if self.local_llm_setting.read().enabled {
      todo!()
    } else {
      self
        .cloud_service
        .stream_complete(workspace_id, text, complete_type)
        .await
    }
  }
}

fn setup_local_ai(local_ai_setting: &LocalLLMSetting, local_llm_ctrl: Arc<LocalChatLLMController>) {
  trace!(
    "[Chat Plugin] setup local ai with setting: {:?}",
    local_ai_setting
  );

  if local_ai_setting.enabled {
    if let Ok(config) = local_ai_setting.chat_plugin_config() {
      tokio::spawn(async move {
        if let Err(err) = local_llm_ctrl.init_chat_plugin(config).await {
          error!("[Chat Plugin] failed to setup plugin: {:?}", err);
        }
      });
    }
  } else {
    tokio::spawn(async move {
      match local_llm_ctrl.destroy_chat_plugin().await {
        Ok(_) => info!("[Chat Plugin] destroy plugin successfully"),
        Err(err) => error!("[Chat Plugin] failed to destroy plugin: {:?}", err),
      }
    });
  }
}

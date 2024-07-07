use crate::chat_manager::ChatUserService;
use crate::entities::{ChatStatePB, ModelTypePB};
use crate::notification::{send_notification, ChatNotification};
use crate::persistence::select_single_message;
use appflowy_local_ai::llm_chat::{LocalChatLLMChat, LocalLLMSetting};
use appflowy_plugin::error::PluginError;
use appflowy_plugin::util::is_apple_silicon;
use flowy_chat_pub::cloud::{
  ChatCloudService, ChatMessage, ChatMessageType, CompletionType, MessageCursor,
  RepeatedChatMessage, RepeatedRelatedQuestion, StreamAnswer, StreamComplete,
};
use flowy_error::{FlowyError, FlowyResult};
use futures::{stream, StreamExt, TryStreamExt};
use lib_infra::async_trait::async_trait;
use lib_infra::future::FutureResult;
use parking_lot::RwLock;
use std::sync::Arc;
use tracing::{error, info, trace};

pub struct ChatService {
  pub cloud_service: Arc<dyn ChatCloudService>,
  user_service: Arc<dyn ChatUserService>,
  local_llm_chat: Arc<LocalChatLLMChat>,
  local_llm_setting: Arc<RwLock<LocalLLMSetting>>,
}

impl ChatService {
  pub fn new(
    user_service: Arc<dyn ChatUserService>,
    cloud_service: Arc<dyn ChatCloudService>,
    local_llm_ctrl: Arc<LocalChatLLMChat>,
    local_llm_setting: LocalLLMSetting,
  ) -> Self {
    if local_llm_setting.enabled {
      setup_local_chat(&local_llm_setting, local_llm_ctrl.clone());
    }

    let mut rx = local_llm_ctrl.subscribe_running_state();
    tokio::spawn(async move {
      while let Ok(state) = rx.recv().await {
        info!("[Chat Plugin] state: {:?}", state);
      }
    });

    Self {
      user_service,
      cloud_service,
      local_llm_chat: local_llm_ctrl,
      local_llm_setting: Arc::new(RwLock::new(local_llm_setting)),
    }
  }

  pub fn notify_open_chat(&self, chat_id: &str) {
    if self.local_llm_setting.read().enabled {
      trace!("[Chat Plugin] notify open chat: {}", chat_id);
      let chat_id = chat_id.to_string();
      let weak_ctrl = Arc::downgrade(&self.local_llm_chat);
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
      trace!("[Chat Plugin] notify close chat: {}", chat_id);
      let weak_ctrl = Arc::downgrade(&self.local_llm_chat);
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

    setup_local_chat(&setting, self.local_llm_chat.clone());
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

  fn handle_plugin_error(&self, err: PluginError) {
    if matches!(
      err,
      PluginError::PluginNotConnected | PluginError::PeerDisconnect
    ) {
      send_notification("appflowy_chat_plugin", ChatNotification::ChatStateUpdated).payload(
        ChatStatePB {
          model_type: ModelTypePB::LocalAI,
          available: false,
        },
      );
    }
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
      match self.local_llm_chat.ask_question(chat_id, &content).await {
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
    if self.local_llm_setting.read().enabled {
      let content = self.get_message_content(question_message_id)?;
      match self.local_llm_chat.generate_answer(chat_id, &content).await {
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

fn setup_local_chat(local_llm_setting: &LocalLLMSetting, llm_chat_ctrl: Arc<LocalChatLLMChat>) {
  if local_llm_setting.enabled {
    if let Ok(mut config) = local_llm_setting.chat_config() {
      tokio::spawn(async move {
        trace!("[Chat Plugin] setup local chat: {:?}", config);
        if is_apple_silicon().await.unwrap_or(false) {
          config = config.with_device("gpu");
        }

        if cfg!(debug_assertions) {
          config = config.with_verbose(true);
        }

        match llm_chat_ctrl.init_chat_plugin(config).await {
          Ok(_) => {
            send_notification("appflowy_chat_plugin", ChatNotification::ChatStateUpdated).payload(
              ChatStatePB {
                model_type: ModelTypePB::LocalAI,
                available: true,
              },
            );
          },
          Err(err) => {
            send_notification("appflowy_chat_plugin", ChatNotification::ChatStateUpdated).payload(
              ChatStatePB {
                model_type: ModelTypePB::LocalAI,
                available: false,
              },
            );
            error!("[Chat Plugin] failed to setup plugin: {:?}", err);
          },
        }
      });
    }
  } else {
    tokio::spawn(async move {
      match llm_chat_ctrl.destroy_chat_plugin().await {
        Ok(_) => info!("[Chat Plugin] destroy plugin successfully"),
        Err(err) => error!("[Chat Plugin] failed to destroy plugin: {:?}", err),
      }
    });
  }
}

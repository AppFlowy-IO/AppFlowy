use crate::chat::Chat;
use crate::entities::RepeatedChatMessagePB;
use dashmap::DashMap;
use flowy_chat_pub::cloud::{ChatCloudService, ChatUserService, MessageOffset};
use flowy_error::FlowyError;
use std::sync::Arc;
use tracing::warn;

pub struct ChatManager {
  cloud_service: Arc<dyn ChatCloudService>,
  user_service: Arc<dyn ChatUserService>,
  chats: DashMap<String, Arc<Chat>>,
}

impl ChatManager {
  pub fn new() -> ChatManager {
    todo!()
  }

  pub async fn open_chat(&self, chat_id: &str) -> Result<(), FlowyError> {
    todo!()
  }

  pub async fn close_chat(&self, chat_id: &str) -> Result<(), FlowyError> {
    todo!()
  }

  pub async fn delete_chat(&self, chat_id: &str) -> Result<(), FlowyError> {
    todo!()
  }

  pub async fn create_chat(&self, uid: &i64, chat_id: &str) -> Result<(), FlowyError> {
    let workspace_id = self.user_service.workspace_id()?;
    self
      .cloud_service
      .create_chat(uid, &workspace_id, chat_id)
      .await?;
    Ok(())
  }

  pub async fn send_chat_message(&self, chat_id: &str, message: &str) -> Result<(), FlowyError> {
    let workspace_id = self.user_service.workspace_id()?;
    self
      .cloud_service
      .send_message(&workspace_id, chat_id, message)
      .await?;
    Ok(())
  }

  pub async fn get_history_messages(
    &self,
    chat_id: &str,
    limit: i64,
    after_message_id: Option<i64>,
    before_message_id: Option<i64>,
  ) -> Result<RepeatedChatMessagePB, FlowyError> {
    if after_message_id.is_some() && before_message_id.is_some() {
      warn!("Cannot specify both after_message_id and before_message_id");
    }
    let workspace_id = self.user_service.workspace_id()?;
    let offset = if after_message_id.is_some() {
      MessageOffset::AfterMessageId(after_message_id.unwrap())
    } else if before_message_id.is_some() {
      MessageOffset::BeforeMessageId(before_message_id.unwrap())
    } else {
      MessageOffset::Offset(0)
    };

    let resp = self
      .cloud_service
      .get_chat_messages(&workspace_id, &chat_id, offset, limit as u64)
      .await?;
    Ok(RepeatedChatMessagePB::from(resp))
  }
}

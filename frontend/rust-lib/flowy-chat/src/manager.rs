use crate::chat::Chat;
use crate::entities::ChatMessageListPB;
use crate::persistence::{insert_chat, ChatTable};
use dashmap::DashMap;
use flowy_chat_pub::cloud::{ChatCloudService, ChatMessageType};
use flowy_error::{FlowyError, FlowyResult};
use flowy_sqlite::DBConnection;
use lib_infra::util::timestamp;
use std::sync::Arc;
use tracing::instrument;

pub trait ChatUserService: Send + Sync + 'static {
  fn user_id(&self) -> Result<i64, FlowyError>;
  fn device_id(&self) -> Result<String, FlowyError>;
  fn workspace_id(&self) -> Result<String, FlowyError>;
  fn sqlite_connection(&self, uid: i64) -> Result<DBConnection, FlowyError>;
}

pub struct ChatManager {
  cloud_service: Arc<dyn ChatCloudService>,
  user_service: Arc<dyn ChatUserService>,
  chats: DashMap<String, Arc<Chat>>,
}

impl ChatManager {
  pub fn new(
    cloud_service: Arc<dyn ChatCloudService>,
    user_service: impl ChatUserService,
  ) -> ChatManager {
    let user_service = Arc::new(user_service);

    Self {
      cloud_service,
      user_service,
      chats: DashMap::new(),
    }
  }

  pub async fn open_chat(&self, chat_id: &str) -> Result<(), FlowyError> {
    self.chats.entry(chat_id.to_string()).or_insert_with(|| {
      Arc::new(Chat::new(
        self.user_service.user_id().unwrap(),
        chat_id.to_string(),
        self.user_service.clone(),
        self.cloud_service.clone(),
      ))
    });

    Ok(())
  }

  pub async fn close_chat(&self, _chat_id: &str) -> Result<(), FlowyError> {
    Ok(())
  }

  pub async fn delete_chat(&self, chat_id: &str) -> Result<(), FlowyError> {
    if let Some((_, chat)) = self.chats.remove(chat_id) {
      chat.close();
    }
    Ok(())
  }

  pub async fn create_chat(&self, uid: &i64, chat_id: &str) -> Result<(), FlowyError> {
    let workspace_id = self.user_service.workspace_id()?;
    self
      .cloud_service
      .create_chat(uid, &workspace_id, chat_id)
      .await?;
    save_chat(self.user_service.sqlite_connection(*uid)?, chat_id)?;

    let chat = Arc::new(Chat::new(
      self.user_service.user_id().unwrap(),
      chat_id.to_string(),
      self.user_service.clone(),
      self.cloud_service.clone(),
    ));
    self.chats.insert(chat_id.to_string(), chat);
    Ok(())
  }

  #[instrument(level = "info", skip_all, err)]
  pub async fn send_chat_message(
    &self,
    chat_id: &str,
    message: &str,
    message_type: ChatMessageType,
  ) -> Result<(), FlowyError> {
    let chat = self.chats.get(chat_id).as_deref().cloned();
    match chat {
      None => Err(FlowyError::internal().with_context("Should call open chat first")),
      Some(chat) => {
        chat.send_chat_message(message, message_type).await?;
        Ok(())
      },
    }
  }

  /// Load chat messages for a given `chat_id`.
  ///
  /// 1. When opening a chat:
  ///    - Loads local chat messages.
  ///    - `after_message_id` and `before_message_id` are `None`.
  ///    - Spawns a task to load messages from the remote server, notifying the user when the remote messages are loaded.
  ///
  /// 2. Loading more messages in an existing chat with `after_message_id`:
  ///    - `after_message_id` is the last message ID in the current chat messages.
  ///
  /// 3. Loading more messages in an existing chat with `before_message_id`:
  ///    - `before_message_id` is the first message ID in the current chat messages.
  ///
  /// 4. `after_message_id` and `before_message_id` cannot be specified at the same time.

  pub async fn load_prev_chat_messages(
    &self,
    chat_id: &str,
    limit: i64,
    before_message_id: Option<i64>,
  ) -> Result<ChatMessageListPB, FlowyError> {
    let chat = self.chats.get(chat_id).as_deref().cloned();
    match chat {
      None => Err(FlowyError::internal().with_context("Should call open chat first")),
      Some(chat) => {
        let list = chat
          .load_prev_chat_messages(limit, before_message_id)
          .await?;
        Ok(list)
      },
    }
  }
}

fn save_chat(conn: DBConnection, chat_id: &str) -> FlowyResult<()> {
  let row = ChatTable {
    chat_id: chat_id.to_string(),
    created_at: timestamp(),
    name: "".to_string(),
  };

  insert_chat(conn, &row)?;
  Ok(())
}

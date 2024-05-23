use crate::chat::Chat;
use crate::entities::{ChatMessagePB, RepeatedChatMessagePB};
use crate::notification::{send_notification, ChatNotification};
use crate::persistence::{
  insert_chat, insert_chat_messages, select_chat_messages, ChatMessageTable, ChatTable,
};
use dashmap::DashMap;
use flowy_chat_pub::cloud::{ChatCloudService, ChatMessage, MessageOffset, RepeatedChatMessage};
use flowy_error::{FlowyError, FlowyResult};
use flowy_sqlite::{DBConnection, QueryResult};
use lib_infra::util::timestamp;
use std::sync::Arc;
use tracing::{error, warn};

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
    Ok(())
  }

  pub async fn close_chat(&self, chat_id: &str) -> Result<(), FlowyError> {
    Ok(())
  }

  pub async fn delete_chat(&self, chat_id: &str) -> Result<(), FlowyError> {
    Ok(())
  }

  pub async fn create_chat(&self, uid: &i64, chat_id: &str) -> Result<(), FlowyError> {
    let workspace_id = self.user_service.workspace_id()?;
    self
      .cloud_service
      .create_chat(uid, &workspace_id, chat_id)
      .await?;
    save_chat(self.user_service.sqlite_connection(*uid)?, chat_id)?;
    Ok(())
  }

  pub async fn send_chat_message(&self, chat_id: &str, message: &str) -> Result<(), FlowyError> {
    let uid = self.user_service.user_id()?;
    let workspace_id = self.user_service.workspace_id()?;
    let message = self
      .cloud_service
      .send_message(&workspace_id, chat_id, message)
      .await?;
    save_chat_message(
      self.user_service.sqlite_connection(uid)?,
      chat_id,
      vec![message],
    )?;
    Ok(())
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

  pub async fn load_chat_messages(
    &self,
    chat_id: &str,
    limit: i64,
    after_message_id: Option<i64>,
    before_message_id: Option<i64>,
  ) -> Result<RepeatedChatMessagePB, FlowyError> {
    let uid = self.user_service.user_id()?;
    let messages = self
      .load_local_chat_messages(uid, chat_id, limit, after_message_id, before_message_id)
      .await?;

    let after_message_id = after_message_id.or_else(|| messages.last().map(|m| m.message_id));
    let before_message_id = before_message_id.or_else(|| messages.first().map(|m| m.message_id));

    if let Err(err) = self
      .load_remote_chat_messages(chat_id, limit, after_message_id, before_message_id)
      .await
    {
      error!("Failed to load remote chat messages: {}", err);
    }
    Ok(RepeatedChatMessagePB {
      messages,
      has_more: true,
    })
  }

  async fn load_local_chat_messages(
    &self,
    uid: i64,
    chat_id: &str,
    limit: i64,
    after_message_id: Option<i64>,
    before_message_id: Option<i64>,
  ) -> Result<Vec<ChatMessagePB>, FlowyError> {
    let conn = self.user_service.sqlite_connection(uid)?;
    let records = select_chat_messages(conn, chat_id, limit, after_message_id, before_message_id)?;
    let messages = records
      .into_iter()
      .map(|record| ChatMessagePB {
        message_id: record.message_id,
        content: record.content,
        created_at: record.created_at,
      })
      .collect::<Vec<_>>();

    Ok(messages)
  }

  async fn load_remote_chat_messages(
    &self,
    chat_id: &str,
    limit: i64,
    after_message_id: Option<i64>,
    before_message_id: Option<i64>,
  ) -> Result<(), FlowyError> {
    let chat_id = chat_id.to_string();
    let user_service = self.user_service.clone();
    let cloud_service = self.cloud_service.clone();
    tokio::spawn(async move {
      let uid = user_service.user_id()?;
      let workspace_id = user_service.workspace_id()?;
      match _load_remote_chat_messages(
        workspace_id,
        chat_id.to_string(),
        limit,
        after_message_id,
        before_message_id,
        cloud_service,
      )
      .await
      {
        Ok(resp) => {
          // Save chat messages to local disk
          save_chat_message(
            user_service.sqlite_connection(uid)?,
            &chat_id,
            resp.messages.clone(),
          )?;
          let pb = RepeatedChatMessagePB::from(resp);
          send_notification(&chat_id, ChatNotification::DidLoadChatMessage)
            .payload(pb)
            .send();
        },
        Err(err) => {
          error!("Failed to load chat messages: {}", err);
        },
      }
      Ok::<(), FlowyError>(())
    });
    Ok(())
  }
}

async fn _load_remote_chat_messages(
  workspace_id: String,
  chat_id: String,
  limit: i64,
  after_message_id: Option<i64>,
  before_message_id: Option<i64>,
  cloud_service: Arc<dyn ChatCloudService>,
) -> Result<RepeatedChatMessage, FlowyError> {
  if after_message_id.is_some() && before_message_id.is_some() {
    warn!("Cannot specify both after_message_id and before_message_id");
  }
  let offset = if after_message_id.is_some() {
    MessageOffset::AfterMessageId(after_message_id.unwrap())
  } else if before_message_id.is_some() {
    MessageOffset::BeforeMessageId(before_message_id.unwrap())
  } else {
    MessageOffset::Offset(0)
  };

  let resp = cloud_service
    .get_chat_messages(&workspace_id, &chat_id, offset, limit as u64)
    .await?;
  Ok(resp)
}

fn save_chat_message(
  conn: DBConnection,
  chat_id: &str,
  messages: Vec<ChatMessage>,
) -> FlowyResult<()> {
  let records = messages
    .into_iter()
    .map(|message| ChatMessageTable {
      message_id: message.message_id,
      chat_id: chat_id.to_string(),
      content: message.content,
      created_at: message.created_at.timestamp(),
    })
    .collect::<Vec<_>>();
  insert_chat_messages(conn, &records)?;
  Ok(())
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

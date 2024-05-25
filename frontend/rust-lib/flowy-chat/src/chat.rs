use crate::entities::{ChatMessageListPB, ChatMessagePB};
use crate::manager::ChatUserService;
use crate::notification::{send_notification, ChatNotification};
use crate::persistence::{
  insert_chat, insert_chat_messages, select_chat_messages, ChatMessageTable, ChatTable,
};
use flowy_chat_pub::cloud::{ChatCloudService, ChatMessage, ChatMessageType, MessageCursor};
use flowy_error::{FlowyError, FlowyResult};
use flowy_sqlite::DBConnection;
use lib_infra::util::timestamp;

use std::sync::Arc;
use tokio::sync::RwLock;
use tracing::{error, instrument, trace};

enum PrevMessageState {
  HasMore,
  NoMore,
  Loading,
}

pub struct Chat {
  chat_id: String,
  uid: i64,
  user_service: Arc<dyn ChatUserService>,
  cloud_service: Arc<dyn ChatCloudService>,
  prev_message_state: Arc<RwLock<PrevMessageState>>,
}

impl Chat {
  pub fn new(
    uid: i64,
    chat_id: String,
    user_service: Arc<dyn ChatUserService>,
    cloud_service: Arc<dyn ChatCloudService>,
  ) -> Chat {
    Chat {
      uid,
      chat_id,
      cloud_service,
      user_service,
      prev_message_state: Arc::new(RwLock::new(PrevMessageState::HasMore)),
    }
  }

  pub fn close(&self) {}

  #[instrument(level = "info", skip_all, err)]
  pub async fn send_chat_message(
    &self,
    message: &str,
    message_type: ChatMessageType,
  ) -> Result<Vec<ChatMessage>, FlowyError> {
    let _uid = self.user_service.user_id()?;
    let workspace_id = self.user_service.workspace_id()?;
    let mut messages = Vec::with_capacity(2);

    trace!(
      "Sending chat message: chat_id={}, message={}, type={:?}",
      self.chat_id,
      message,
      message_type
    );
    match message_type {
      ChatMessageType::System => {
        let message = self
          .cloud_service
          .send_system_message(&workspace_id, &self.chat_id, message)
          .await?;
        messages.push(message);
      },
      ChatMessageType::User => {
        let qa = self
          .cloud_service
          .send_user_message(&workspace_id, &self.chat_id, message)
          .await?;
        messages.push(qa.question);
        if let Some(answer) = qa.answer {
          messages.push(answer);
        }
      },
    };

    trace!(
      "Saving chat messages to local disk: chat_id={}, messages:{:?}",
      self.chat_id,
      messages
    );

    save_chat_message(
      self.user_service.sqlite_connection(self.uid)?,
      &self.chat_id,
      messages.clone(),
    )?;
    Ok(messages)
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
    limit: i64,
    before_message_id: Option<i64>,
  ) -> Result<ChatMessageListPB, FlowyError> {
    trace!(
      "Loading old messages: chat_id={}, limit={}, before_message_id={:?}",
      self.chat_id,
      limit,
      before_message_id
    );
    let messages = self
      .load_local_chat_messages(limit, None, before_message_id)
      .await?;

    // If the number of messages equals the limit, then no need to load more messages from remote
    let has_more = !messages.is_empty();
    if messages.len() == limit as usize {
      return Ok(ChatMessageListPB {
        messages,
        has_more,
        total: 0,
      });
    }

    if matches!(
      *self.prev_message_state.read().await,
      PrevMessageState::HasMore
    ) {
      *self.prev_message_state.write().await = PrevMessageState::Loading;
      if let Err(err) = self
        .load_remote_chat_messages(limit, before_message_id, None)
        .await
      {
        error!("Failed to load chat messages: {}", err);
      }
    }

    Ok(ChatMessageListPB {
      messages,
      has_more,
      total: 0,
    })
  }

  #[allow(dead_code)]
  pub async fn load_after_chat_messages(
    &self,
    limit: i64,
    after_message_id: Option<i64>,
  ) -> Result<ChatMessageListPB, FlowyError> {
    trace!(
      "Loading new messages: chat_id={}, limit={}, after_message_id={:?}",
      self.chat_id,
      limit,
      after_message_id,
    );
    let messages = self
      .load_local_chat_messages(limit, after_message_id, None)
      .await?;

    // If the number of messages equals the limit, then no need to load more messages from remote
    let has_more = !messages.is_empty();
    if messages.len() == limit as usize {
      return Ok(ChatMessageListPB {
        messages,
        has_more,
        total: 0,
      });
    }

    let _ = self
      .load_remote_chat_messages(limit, None, after_message_id)
      .await;
    Ok(ChatMessageListPB {
      messages,
      has_more,
      total: 0,
    })
  }

  async fn load_remote_chat_messages(
    &self,
    limit: i64,
    before_message_id: Option<i64>,
    after_message_id: Option<i64>,
  ) -> FlowyResult<()> {
    trace!(
      "Loading chat messages from remote: chat_id={}, limit={}, before_message_id={:?}, after_message_id={:?}",
      self.chat_id,
      limit,
      before_message_id,
      after_message_id
    );
    let workspace_id = self.user_service.workspace_id()?;
    let chat_id = self.chat_id.clone();
    let cloud_service = self.cloud_service.clone();
    let user_service = self.user_service.clone();
    let uid = self.uid;
    let prev_message_state = self.prev_message_state.clone();
    tokio::spawn(async move {
      let cursor = match (before_message_id, after_message_id) {
        (Some(bid), _) => MessageCursor::BeforeMessageId(bid),
        (_, Some(aid)) => MessageCursor::AfterMessageId(aid),
        _ => MessageCursor::NextBack,
      };
      match cloud_service
        .get_chat_messages(&workspace_id, &chat_id, cursor.clone(), limit as u64)
        .await
      {
        Ok(resp) => {
          // Save chat messages to local disk
          save_chat_message(
            user_service.sqlite_connection(uid)?,
            &chat_id,
            resp.messages.clone(),
          )?;

          if matches!(cursor, MessageCursor::BeforeMessageId(_)) {
            if resp.has_more {
              *prev_message_state.write().await = PrevMessageState::HasMore;
            } else {
              *prev_message_state.write().await = PrevMessageState::NoMore;
            }
          }

          let pb = ChatMessageListPB::from(resp);
          send_notification(&chat_id, ChatNotification::DidLoadChatMessage)
            .payload(pb)
            .send();
        },
        Err(err) => error!("Failed to load chat messages: {}", err),
      }
      Ok::<(), FlowyError>(())
    });
    Ok(())
  }

  async fn load_local_chat_messages(
    &self,
    limit: i64,
    after_message_id: Option<i64>,
    before_message_id: Option<i64>,
  ) -> Result<Vec<ChatMessagePB>, FlowyError> {
    let conn = self.user_service.sqlite_connection(self.uid)?;
    let records = select_chat_messages(
      conn,
      &self.chat_id,
      limit,
      after_message_id,
      before_message_id,
    )?;
    let messages = records
      .into_iter()
      .map(|record| ChatMessagePB {
        message_id: record.message_id,
        content: record.content,
        created_at: record.created_at,
        author_type: record.author_type,
        author_id: record.author_id,
      })
      .collect::<Vec<_>>();

    Ok(messages)
  }
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
      author_type: message.author.author_type as i64,
      author_id: message.author.author_id.to_string(),
    })
    .collect::<Vec<_>>();
  insert_chat_messages(conn, &records)?;
  Ok(())
}

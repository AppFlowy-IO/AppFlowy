use crate::entities::{ChatMessageErrorPB, ChatMessageListPB, ChatMessagePB};
use crate::manager::ChatUserService;
use crate::notification::{send_notification, ChatNotification};
use crate::persistence::{insert_chat_messages, select_chat_messages, ChatMessageTable};
use flowy_chat_pub::cloud::{ChatCloudService, ChatMessage, ChatMessageType, MessageCursor};
use flowy_error::{FlowyError, FlowyResult};
use flowy_sqlite::DBConnection;
use futures::StreamExt;
use std::sync::atomic::AtomicI64;
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
  latest_message_id: Arc<AtomicI64>,
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
      latest_message_id: Default::default(),
    }
  }

  pub fn close(&self) {}

  #[allow(dead_code)]
  pub async fn pull_latest_message(&self, limit: i64) {
    let latest_message_id = self
      .latest_message_id
      .load(std::sync::atomic::Ordering::Relaxed);
    if latest_message_id > 0 {
      let _ = self
        .load_remote_chat_messages(limit, None, Some(latest_message_id))
        .await;
    }
  }

  #[instrument(level = "info", skip_all, err)]
  pub async fn send_chat_message(
    &self,
    message: &str,
    message_type: ChatMessageType,
  ) -> Result<(), FlowyError> {
    let uid = self.user_service.user_id()?;
    let workspace_id = self.user_service.workspace_id()?;
    stream_send_chat_messages(
      uid,
      workspace_id,
      self.chat_id.clone(),
      message.to_string(),
      message_type,
      self.cloud_service.clone(),
      self.user_service.clone(),
    );

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

  pub async fn load_latest_chat_messages(
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

    trace!(
      "Loaded local chat messages: chat_id={}, messages={}",
      self.chat_id,
      messages.len()
    );

    // If the number of messages equals the limit, then no need to load more messages from remote
    let has_more = !messages.is_empty();
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
    let latest_message_id = self.latest_message_id.clone();
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
          if let Err(err) = save_chat_message(
            user_service.sqlite_connection(uid)?,
            &chat_id,
            resp.messages.clone(),
          ) {
            error!("Failed to save chat:{} messages: {}", chat_id, err);
          }

          // Update latest message ID
          if !resp.messages.is_empty() {
            latest_message_id.store(
              resp.messages[0].message_id,
              std::sync::atomic::Ordering::Relaxed,
            );
          }

          let pb = ChatMessageListPB::from(resp);
          trace!(
            "Loaded chat messages from remote: chat_id={}, messages={}",
            chat_id,
            pb.messages.len()
          );
          if matches!(cursor, MessageCursor::BeforeMessageId(_)) {
            if pb.has_more {
              *prev_message_state.write().await = PrevMessageState::HasMore;
            } else {
              *prev_message_state.write().await = PrevMessageState::NoMore;
            }
            send_notification(&chat_id, ChatNotification::DidLoadPrevChatMessage)
              .payload(pb)
              .send();
          } else {
            send_notification(&chat_id, ChatNotification::DidLoadLatestChatMessage)
              .payload(pb)
              .send();
          }
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
        has_following: false,
        reply_message_id: record.reply_message_id,
      })
      .collect::<Vec<_>>();

    Ok(messages)
  }
}

fn stream_send_chat_messages(
  uid: i64,
  workspace_id: String,
  chat_id: String,
  message_content: String,
  message_type: ChatMessageType,
  cloud_service: Arc<dyn ChatCloudService>,
  user_service: Arc<dyn ChatUserService>,
) {
  tokio::spawn(async move {
    trace!(
      "Sending chat message: chat_id={}, message={}, type={:?}",
      chat_id,
      message_content,
      message_type
    );

    let mut messages = Vec::with_capacity(2);
    let stream_result = cloud_service
      .send_chat_message(&workspace_id, &chat_id, &message_content, message_type)
      .await;

    let mut reply_message_id = None;

    // By default, stream only returns two messages:
    // 1. user message
    // 2. ai response message
    match stream_result {
      Ok(mut stream) => {
        while let Some(result) = stream.next().await {
          match result {
            Ok(message) => {
              let mut pb = ChatMessagePB::from(message.clone());
              if reply_message_id.is_none() {
                pb.has_following = true;
                reply_message_id = Some(pb.message_id);
              } else {
                pb.reply_message_id = reply_message_id;
              }
              send_notification(&chat_id, ChatNotification::DidReceiveChatMessage)
                .payload(pb)
                .send();
              messages.push(message);
            },
            Err(err) => {
              error!("Failed to send chat message: {}", err);
              let pb = ChatMessageErrorPB {
                chat_id: chat_id.clone(),
                content: message_content.clone(),
                error_message: "Service Temporarily Unavailable".to_string(),
              };
              send_notification(&chat_id, ChatNotification::ChatMessageError)
                .payload(pb)
                .send();
              break;
            },
          }
        }

        // Mark chat as finished
        send_notification(&chat_id, ChatNotification::FinishAnswerQuestion).send();
      },
      Err(err) => {
        error!("Failed to send chat message: {}", err);
        let pb = ChatMessageErrorPB {
          chat_id: chat_id.clone(),
          content: message_content.clone(),
          error_message: err.to_string(),
        };
        send_notification(&chat_id, ChatNotification::ChatMessageError)
          .payload(pb)
          .send();
        return;
      },
    }

    if messages.is_empty() {
      return;
    }

    trace!(
      "Saving chat messages to local disk: chat_id={}, messages:{:?}",
      chat_id,
      messages
    );

    // Insert chat messages to local disk
    if let Err(err) = user_service.sqlite_connection(uid).and_then(|conn| {
      let records = messages
        .into_iter()
        .map(|message| ChatMessageTable {
          message_id: message.message_id,
          chat_id: chat_id.clone(),
          content: message.content,
          created_at: message.created_at.timestamp(),
          author_type: message.author.author_type as i64,
          author_id: message.author.author_id.to_string(),
          reply_message_id,
        })
        .collect::<Vec<_>>();
      insert_chat_messages(conn, &records)?;
      Ok(())
    }) {
      error!("Failed to save chat messages: {}", err);
    }
  });
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
      reply_message_id: None,
    })
    .collect::<Vec<_>>();
  insert_chat_messages(conn, &records)?;
  Ok(())
}

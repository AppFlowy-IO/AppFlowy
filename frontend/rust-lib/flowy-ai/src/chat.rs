use crate::ai_manager::AIUserService;
use crate::entities::{
  ChatMessageErrorPB, ChatMessageListPB, ChatMessagePB, RepeatedRelatedQuestionPB,
};
use crate::middleware::chat_service_mw::AICloudServiceMiddleware;
use crate::notification::{make_notification, ChatNotification};
use crate::persistence::{
  insert_chat_messages, read_chat_metadata, select_chat_messages, update_chat, ChatMessageTable,
  ChatTableChangeset,
};
use allo_isolate::Isolate;
use flowy_ai_pub::cloud::{
  ChatCloudService, ChatMessage, ChatMessageMetadata, ChatMessageType, MessageCursor,
  QuestionStreamValue,
};
use flowy_error::{FlowyError, FlowyResult};
use flowy_sqlite::DBConnection;
use futures::{SinkExt, StreamExt};
use lib_infra::isolate_stream::IsolateSink;
use std::path::PathBuf;
use std::sync::atomic::{AtomicBool, AtomicI64};
use std::sync::Arc;
use tokio::sync::{Mutex, RwLock};
use tracing::{error, instrument, trace};

enum PrevMessageState {
  HasMore,
  NoMore,
  Loading,
}

pub struct Chat {
  chat_id: String,
  uid: i64,
  user_service: Arc<dyn AIUserService>,
  chat_service: Arc<AICloudServiceMiddleware>,
  prev_message_state: Arc<RwLock<PrevMessageState>>,
  latest_message_id: Arc<AtomicI64>,
  stop_stream: Arc<AtomicBool>,
  stream_buffer: Arc<Mutex<StringBuffer>>,
}

impl Chat {
  pub fn new(
    uid: i64,
    chat_id: String,
    user_service: Arc<dyn AIUserService>,
    chat_service: Arc<AICloudServiceMiddleware>,
  ) -> Chat {
    Chat {
      uid,
      chat_id,
      chat_service,
      user_service,
      prev_message_state: Arc::new(RwLock::new(PrevMessageState::HasMore)),
      latest_message_id: Default::default(),
      stop_stream: Arc::new(AtomicBool::new(false)),
      stream_buffer: Arc::new(Mutex::new(StringBuffer::default())),
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

  pub async fn stop_stream_message(&self) {
    self
      .stop_stream
      .store(true, std::sync::atomic::Ordering::SeqCst);
  }

  #[instrument(level = "info", skip_all, err)]
  pub async fn stream_chat_message(
    &self,
    message: &str,
    message_type: ChatMessageType,
    text_stream_port: i64,
    metadata: Vec<ChatMessageMetadata>,
  ) -> Result<ChatMessagePB, FlowyError> {
    if message.len() > 2000 {
      return Err(FlowyError::text_too_long().with_context("Exceeds maximum message 2000 length"));
    }
    // clear
    self
      .stop_stream
      .store(false, std::sync::atomic::Ordering::SeqCst);
    self.stream_buffer.lock().await.clear();

    let stream_buffer = self.stream_buffer.clone();
    let uid = self.user_service.user_id()?;
    let workspace_id = self.user_service.workspace_id()?;

    let question = self
      .chat_service
      .create_question(
        &workspace_id,
        &self.chat_id,
        message,
        message_type,
        metadata,
      )
      .await
      .map_err(|err| {
        error!("Failed to send question: {}", err);
        FlowyError::server_error()
      })?;

    save_chat_message(
      self.user_service.sqlite_connection(uid)?,
      &self.chat_id,
      vec![question.clone()],
    )?;

    let stop_stream = self.stop_stream.clone();
    let chat_id = self.chat_id.clone();
    let question_id = question.message_id;
    let cloud_service = self.chat_service.clone();
    let user_service = self.user_service.clone();
    tokio::spawn(async move {
      let mut text_sink = IsolateSink::new(Isolate::new(text_stream_port));
      match cloud_service
        .stream_answer(&workspace_id, &chat_id, question_id)
        .await
      {
        Ok(mut stream) => {
          while let Some(message) = stream.next().await {
            match message {
              Ok(message) => {
                if stop_stream.load(std::sync::atomic::Ordering::Relaxed) {
                  trace!("[Chat] stop streaming message");
                  break;
                }
                match message {
                  QuestionStreamValue::Answer { value } => {
                    stream_buffer.lock().await.push_str(&value);
                    let _ = text_sink.send(format!("data:{}", value)).await;
                  },
                  QuestionStreamValue::Metadata { value } => {
                    if let Ok(s) = serde_json::to_string(&value) {
                      stream_buffer.lock().await.set_metadata(value);
                      let _ = text_sink.send(format!("metadata:{}", s)).await;
                    }
                  },
                }
              },
              Err(err) => {
                error!("[Chat] failed to stream answer: {}", err);
                let _ = text_sink.send(format!("error:{}", err)).await;
                let pb = ChatMessageErrorPB {
                  chat_id: chat_id.clone(),
                  error_message: err.to_string(),
                };
                make_notification(&chat_id, ChatNotification::StreamChatMessageError)
                  .payload(pb)
                  .send();
                return Err(err);
              },
            }
          }
        },
        Err(err) => {
          error!("[Chat] failed to stream answer: {}", err);
          if err.is_ai_response_limit_exceeded() {
            let _ = text_sink.send("AI_RESPONSE_LIMIT".to_string()).await;
          } else {
            let _ = text_sink.send(format!("error:{}", err)).await;
          }

          let pb = ChatMessageErrorPB {
            chat_id: chat_id.clone(),
            error_message: err.to_string(),
          };
          make_notification(&chat_id, ChatNotification::StreamChatMessageError)
            .payload(pb)
            .send();
          return Err(err);
        },
      }

      make_notification(&chat_id, ChatNotification::FinishStreaming).send();
      if stream_buffer.lock().await.is_empty() {
        return Ok(());
      }
      let content = stream_buffer.lock().await.take_content();
      let metadata = stream_buffer.lock().await.take_metadata();

      let answer = cloud_service
        .create_answer(&workspace_id, &chat_id, &content, question_id, metadata)
        .await?;
      Self::save_answer(uid, &chat_id, &user_service, answer)?;
      Ok::<(), FlowyError>(())
    });

    let question_pb = ChatMessagePB::from(question);
    Ok(question_pb)
  }

  fn save_answer(
    uid: i64,
    chat_id: &str,
    user_service: &Arc<dyn AIUserService>,
    answer: ChatMessage,
  ) -> Result<(), FlowyError> {
    trace!("[Chat] save answer: answer={:?}", answer);
    save_chat_message(
      user_service.sqlite_connection(uid)?,
      chat_id,
      vec![answer.clone()],
    )?;
    let pb = ChatMessagePB::from(answer);
    make_notification(chat_id, ChatNotification::DidReceiveChatMessage)
      .payload(pb)
      .send();

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
      "[Chat] Loading messages from disk: chat_id={}, limit={}, before_message_id={:?}",
      self.chat_id,
      limit,
      before_message_id
    );
    let messages = self
      .load_local_chat_messages(limit, None, before_message_id)
      .await?;

    // If the number of messages equals the limit, then no need to load more messages from remote
    if messages.len() == limit as usize {
      let pb = ChatMessageListPB {
        messages,
        has_more: true,
        total: 0,
      };
      make_notification(&self.chat_id, ChatNotification::DidLoadPrevChatMessage)
        .payload(pb.clone())
        .send();
      return Ok(pb);
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
        error!("Failed to load previous chat messages: {}", err);
      }
    }

    Ok(ChatMessageListPB {
      messages,
      has_more: true,
      total: 0,
    })
  }

  pub async fn load_latest_chat_messages(
    &self,
    limit: i64,
    after_message_id: Option<i64>,
  ) -> Result<ChatMessageListPB, FlowyError> {
    trace!(
      "[Chat] Loading new messages: chat_id={}, limit={}, after_message_id={:?}",
      self.chat_id,
      limit,
      after_message_id,
    );
    let messages = self
      .load_local_chat_messages(limit, after_message_id, None)
      .await?;

    trace!(
      "[Chat] Loaded local chat messages: chat_id={}, messages={}",
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
      "[Chat] start loading messages from remote: chat_id={}, limit={}, before_message_id={:?}, after_message_id={:?}",
      self.chat_id,
      limit,
      before_message_id,
      after_message_id
    );
    let workspace_id = self.user_service.workspace_id()?;
    let chat_id = self.chat_id.clone();
    let cloud_service = self.chat_service.clone();
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
            "[Chat] Loaded messages from remote: chat_id={}, messages={}, hasMore: {}, cursor:{:?}",
            chat_id,
            pb.messages.len(),
            pb.has_more,
            cursor,
          );
          if matches!(cursor, MessageCursor::BeforeMessageId(_)) {
            if pb.has_more {
              *prev_message_state.write().await = PrevMessageState::HasMore;
            } else {
              *prev_message_state.write().await = PrevMessageState::NoMore;
            }
            make_notification(&chat_id, ChatNotification::DidLoadPrevChatMessage)
              .payload(pb)
              .send();
          } else {
            make_notification(&chat_id, ChatNotification::DidLoadLatestChatMessage)
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

  pub async fn get_related_question(
    &self,
    message_id: i64,
  ) -> Result<RepeatedRelatedQuestionPB, FlowyError> {
    let workspace_id = self.user_service.workspace_id()?;
    let resp = self
      .chat_service
      .get_related_message(&workspace_id, &self.chat_id, message_id)
      .await?;

    trace!(
      "[Chat] related messages: chat_id={}, message_id={}, messages:{:?}",
      self.chat_id,
      message_id,
      resp.items
    );
    Ok(RepeatedRelatedQuestionPB::from(resp))
  }

  #[instrument(level = "debug", skip_all, err)]
  pub async fn generate_answer(&self, question_message_id: i64) -> FlowyResult<ChatMessagePB> {
    trace!(
      "[Chat] generate answer: chat_id={}, question_message_id={}",
      self.chat_id,
      question_message_id
    );
    let workspace_id = self.user_service.workspace_id()?;
    let answer = self
      .chat_service
      .get_answer(&workspace_id, &self.chat_id, question_message_id)
      .await?;

    Self::save_answer(self.uid, &self.chat_id, &self.user_service, answer.clone())?;
    let pb = ChatMessagePB::from(answer);
    Ok(pb)
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
        reply_message_id: record.reply_message_id,
        metadata: record.metadata,
      })
      .collect::<Vec<_>>();

    Ok(messages)
  }

  #[instrument(level = "debug", skip_all, err)]
  pub async fn index_file(&self, file_path: PathBuf) -> FlowyResult<()> {
    if !file_path.exists() {
      return Err(
        FlowyError::record_not_found().with_context(format!("{:?} not exist", file_path)),
      );
    }

    if !file_path.is_file() {
      return Err(
        FlowyError::invalid_data().with_context(format!("{:?} is not a file ", file_path)),
      );
    }

    trace!(
      "[Chat] index file: chat_id={}, file_path={:?}",
      self.chat_id,
      file_path
    );
    self
      .chat_service
      .index_file(
        &self.user_service.workspace_id()?,
        &file_path,
        &self.chat_id,
      )
      .await?;

    let file_name = file_path
      .file_name()
      .unwrap_or_default()
      .to_str()
      .unwrap_or_default();

    let mut conn = self.user_service.sqlite_connection(self.uid)?;
    conn.immediate_transaction(|conn| {
      let mut metadata = read_chat_metadata(conn, &self.chat_id)?;
      metadata.add_file(
        file_name.to_string(),
        file_path.to_str().unwrap_or_default().to_string(),
      );
      let changeset = ChatTableChangeset::from_metadata(metadata);
      update_chat(conn, changeset)?;
      Ok::<(), FlowyError>(())
    })?;

    trace!(
      "[Chat] created index file record: chat_id={}, file_path={:?}",
      self.chat_id,
      file_path
    );

    Ok(())
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
      reply_message_id: message.reply_message_id,
      metadata: Some(serde_json::to_string(&message.meta_data).unwrap_or_default()),
    })
    .collect::<Vec<_>>();
  insert_chat_messages(conn, &records)?;
  Ok(())
}

#[derive(Debug, Default)]
struct StringBuffer {
  content: String,
  metadata: Option<serde_json::Value>,
}

impl StringBuffer {
  fn clear(&mut self) {
    self.content.clear();
    self.metadata = None;
  }

  fn push_str(&mut self, value: &str) {
    self.content.push_str(value);
  }

  fn set_metadata(&mut self, value: serde_json::Value) {
    self.metadata = Some(value);
  }

  fn is_empty(&self) -> bool {
    self.content.is_empty()
  }

  fn take_metadata(&mut self) -> Option<serde_json::Value> {
    self.metadata.take()
  }

  fn take_content(&mut self) -> String {
    std::mem::take(&mut self.content)
  }
}

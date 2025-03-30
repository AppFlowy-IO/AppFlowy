use crate::ai_manager::AIUserService;
use crate::entities::{
  ChatMessageErrorPB, ChatMessageListPB, ChatMessagePB, PredefinedFormatPB,
  RepeatedRelatedQuestionPB, StreamMessageParams,
};
use crate::middleware::chat_service_mw::AICloudServiceMiddleware;
use crate::notification::{chat_notification_builder, ChatNotification};
use crate::persistence::{
  insert_chat_messages, select_chat_messages, select_message_where_match_reply_message_id,
  ChatMessageTable,
};
use crate::stream_message::StreamMessage;
use allo_isolate::Isolate;
use flowy_ai_pub::cloud::{
  AIModel, ChatCloudService, ChatMessage, MessageCursor, QuestionStreamValue, ResponseFormat,
};
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
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
    params: &StreamMessageParams,
    preferred_ai_model: Option<AIModel>,
  ) -> Result<ChatMessagePB, FlowyError> {
    trace!(
      "[Chat] stream chat message: chat_id={}, message={}, message_type={:?}, metadata={:?}, format={:?}",
      self.chat_id,
      params.message,
      params.message_type,
      params.metadata,
      params.format,
    );

    // clear
    self
      .stop_stream
      .store(false, std::sync::atomic::Ordering::SeqCst);
    self.stream_buffer.lock().await.clear();

    let mut question_sink = IsolateSink::new(Isolate::new(params.question_stream_port));
    let answer_stream_buffer = self.stream_buffer.clone();
    let uid = self.user_service.user_id()?;
    let workspace_id = self.user_service.workspace_id()?;

    let _ = question_sink
      .send(StreamMessage::Text(params.message.to_string()).to_string())
      .await;
    let question = self
      .chat_service
      .create_question(
        &workspace_id,
        &self.chat_id,
        &params.message,
        params.message_type.clone(),
        &[],
      )
      .await
      .map_err(|err| {
        error!("Failed to send question: {}", err);
        FlowyError::server_error()
      })?;

    let _ = question_sink
      .send(StreamMessage::MessageId(question.message_id).to_string())
      .await;

    if let Err(err) = self
      .chat_service
      .index_message_metadata(&self.chat_id, &params.metadata, &mut question_sink)
      .await
    {
      error!("Failed to index file: {}", err);
    }

    // Save message to disk
    save_and_notify_message(uid, &self.chat_id, &self.user_service, question.clone())?;
    let format = params.format.clone().map(Into::into).unwrap_or_default();
    self.stream_response(
      params.answer_stream_port,
      answer_stream_buffer,
      uid,
      workspace_id,
      question.message_id,
      format,
      preferred_ai_model,
    );

    let question_pb = ChatMessagePB::from(question);
    Ok(question_pb)
  }

  #[instrument(level = "info", skip_all, err)]
  pub async fn stream_regenerate_response(
    &self,
    question_id: i64,
    answer_stream_port: i64,
    format: Option<PredefinedFormatPB>,
    ai_model: Option<AIModel>,
  ) -> FlowyResult<()> {
    trace!(
      "[Chat] regenerate and stream chat message: chat_id={}",
      self.chat_id,
    );

    // clear
    self
      .stop_stream
      .store(false, std::sync::atomic::Ordering::SeqCst);
    self.stream_buffer.lock().await.clear();

    let format = format.map(Into::into).unwrap_or_default();

    let answer_stream_buffer = self.stream_buffer.clone();
    let uid = self.user_service.user_id()?;
    let workspace_id = self.user_service.workspace_id()?;

    self.stream_response(
      answer_stream_port,
      answer_stream_buffer,
      uid,
      workspace_id,
      question_id,
      format,
      ai_model,
    );

    Ok(())
  }

  #[allow(clippy::too_many_arguments)]
  fn stream_response(
    &self,
    answer_stream_port: i64,
    answer_stream_buffer: Arc<Mutex<StringBuffer>>,
    uid: i64,
    workspace_id: String,
    question_id: i64,
    format: ResponseFormat,
    ai_model: Option<AIModel>,
  ) {
    let stop_stream = self.stop_stream.clone();
    let chat_id = self.chat_id.clone();
    let cloud_service = self.chat_service.clone();
    let user_service = self.user_service.clone();
    tokio::spawn(async move {
      let mut answer_sink = IsolateSink::new(Isolate::new(answer_stream_port));
      match cloud_service
        .stream_answer(&workspace_id, &chat_id, question_id, format, ai_model)
        .await
      {
        Ok(mut stream) => {
          while let Some(message) = stream.next().await {
            match message {
              Ok(message) => {
                if stop_stream.load(std::sync::atomic::Ordering::Relaxed) {
                  trace!("[Chat] client stop streaming message");
                  break;
                }
                match message {
                  QuestionStreamValue::Answer { value } => {
                    answer_stream_buffer.lock().await.push_str(&value);
                    if let Err(err) = answer_sink
                      .send(StreamMessage::OnData(value).to_string())
                      .await
                    {
                      error!("Failed to stream answer via IsolateSink: {}", err);
                    }
                  },
                  QuestionStreamValue::Metadata { value } => {
                    if let Ok(s) = serde_json::to_string(&value) {
                      // trace!("[Chat] stream metadata: {}", s);
                      answer_stream_buffer.lock().await.set_metadata(value);
                      let _ = answer_sink
                        .send(StreamMessage::Metadata(s).to_string())
                        .await;
                    }
                  },
                  QuestionStreamValue::KeepAlive => {
                    // trace!("[Chat] stream keep alive");
                  },
                }
              },
              Err(err) => {
                if err.code == ErrorCode::RequestTimeout || err.code == ErrorCode::Internal {
                  error!("[Chat] unexpected stream error: {}", err);
                  let _ = answer_sink.send(StreamMessage::Done.to_string()).await;
                } else {
                  error!("[Chat] failed to stream answer: {}", err);
                  let _ = answer_sink
                    .send(StreamMessage::OnError(err.msg.clone()).to_string())
                    .await;
                  let pb = ChatMessageErrorPB {
                    chat_id: chat_id.clone(),
                    error_message: err.to_string(),
                  };
                  chat_notification_builder(&chat_id, ChatNotification::StreamChatMessageError)
                    .payload(pb)
                    .send();
                  return Err(err);
                }
              },
            }
          }
        },
        Err(err) => {
          error!("[Chat] failed to start streaming: {}", err);
          if err.is_ai_response_limit_exceeded() {
            let _ = answer_sink.send("AI_RESPONSE_LIMIT".to_string()).await;
          } else if err.is_ai_image_response_limit_exceeded() {
            let _ = answer_sink
              .send("AI_IMAGE_RESPONSE_LIMIT".to_string())
              .await;
          } else if err.is_ai_max_required() {
            let _ = answer_sink
              .send(format!("AI_MAX_REQUIRED:{}", err.msg))
              .await;
          } else if err.is_local_ai_not_ready() {
            let _ = answer_sink
              .send(format!("LOCAL_AI_NOT_READY:{}", err.msg))
              .await;
          } else if err.is_local_ai_disabled() {
            let _ = answer_sink
              .send(format!("LOCAL_AI_DISABLED:{}", err.msg))
              .await;
          } else {
            let _ = answer_sink
              .send(StreamMessage::OnError(err.msg.clone()).to_string())
              .await;
          }

          let pb = ChatMessageErrorPB {
            chat_id: chat_id.clone(),
            error_message: err.to_string(),
          };
          chat_notification_builder(&chat_id, ChatNotification::StreamChatMessageError)
            .payload(pb)
            .send();
          return Err(err);
        },
      }

      chat_notification_builder(&chat_id, ChatNotification::FinishStreaming).send();
      trace!("[Chat] finish streaming");

      if answer_stream_buffer.lock().await.is_empty() {
        return Ok(());
      }
      let content = answer_stream_buffer.lock().await.take_content();
      let metadata = answer_stream_buffer.lock().await.take_metadata();
      let answer = cloud_service
        .create_answer(
          &workspace_id,
          &chat_id,
          content.trim(),
          question_id,
          metadata,
        )
        .await?;
      save_and_notify_message(uid, &chat_id, &user_service, answer)?;
      Ok::<(), FlowyError>(())
    });
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
      chat_notification_builder(&self.chat_id, ChatNotification::DidLoadPrevChatMessage)
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
          if let Err(err) = save_chat_message_disk(
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
            chat_notification_builder(&chat_id, ChatNotification::DidLoadPrevChatMessage)
              .payload(pb)
              .send();
          } else {
            chat_notification_builder(&chat_id, ChatNotification::DidLoadLatestChatMessage)
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

  pub async fn get_question_id_from_answer_id(
    &self,
    answer_message_id: i64,
  ) -> Result<i64, FlowyError> {
    let conn = self.user_service.sqlite_connection(self.uid)?;

    let local_result = select_message_where_match_reply_message_id(conn, answer_message_id)?
      .map(|message| message.message_id);

    if let Some(message_id) = local_result {
      return Ok(message_id);
    }

    let workspace_id = self.user_service.workspace_id()?;
    let chat_id = self.chat_id.clone();
    let cloud_service = self.chat_service.clone();

    let question = cloud_service
      .get_question_from_answer_id(&workspace_id, &chat_id, answer_message_id)
      .await?;

    Ok(question.message_id)
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

    save_and_notify_message(self.uid, &self.chat_id, &self.user_service, answer.clone())?;
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
      .embed_file(
        &self.user_service.workspace_id()?,
        &file_path,
        &self.chat_id,
        None,
      )
      .await?;

    trace!(
      "[Chat] created index file record: chat_id={}, file_path={:?}",
      self.chat_id,
      file_path
    );

    Ok(())
  }
}

fn save_chat_message_disk(
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

pub(crate) fn save_and_notify_message(
  uid: i64,
  chat_id: &str,
  user_service: &Arc<dyn AIUserService>,
  message: ChatMessage,
) -> Result<(), FlowyError> {
  trace!("[Chat] save answer: answer={:?}", message);
  save_chat_message_disk(
    user_service.sqlite_connection(uid)?,
    chat_id,
    vec![message.clone()],
  )?;
  let pb = ChatMessagePB::from(message);
  chat_notification_builder(chat_id, ChatNotification::DidReceiveChatMessage)
    .payload(pb)
    .send();

  Ok(())
}

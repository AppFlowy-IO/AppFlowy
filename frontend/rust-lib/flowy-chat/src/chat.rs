use crate::entities::{
  ChatMessageErrorPB, ChatMessageListPB, ChatMessagePB, RepeatedRelatedQuestionPB,
};
use crate::manager::ChatUserService;
use crate::notification::{send_notification, ChatNotification};
use crate::persistence::{
  insert_answer_message, insert_chat_messages, select_chat_messages, ChatMessageTable,
};
use allo_isolate::Isolate;
use flowy_chat_pub::cloud::{
  ChatCloudService, ChatMessage, ChatMessageType, EitherStringOrChatMessage, MessageCursor,
  StreamAnswer,
};
use flowy_error::{FlowyError, FlowyResult};
use flowy_sqlite::DBConnection;
use futures::{SinkExt, StreamExt};
use lib_infra::isolate_stream::IsolateSink;
use std::sync::atomic::{AtomicBool, AtomicI64};
use std::sync::Arc;
use tokio::sync::RwLock;
use tracing::{error, info, instrument, trace};

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
  stop_stream: Arc<AtomicBool>,
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
      stop_stream: Arc::new(AtomicBool::new(false)),
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
  ) -> Result<ChatMessagePB, FlowyError> {
    if message.len() > 2000 {
      return Err(FlowyError::text_too_long().with_context("Exceeds maximum message 2000 length"));
    }

    self
      .stop_stream
      .store(false, std::sync::atomic::Ordering::SeqCst);
    let uid = self.user_service.user_id()?;
    let workspace_id = self.user_service.workspace_id()?;
    let question = self
      .cloud_service
      .send_question(&workspace_id, &self.chat_id, message, message_type)
      .await?;

    save_chat_message(
      self.user_service.sqlite_connection(uid)?,
      &self.chat_id,
      vec![question.clone()],
    )?;

    let stop_stream = self.stop_stream.clone();
    let chat_id = self.chat_id.clone();
    let question_id = question.message_id;
    let cloud_service = self.cloud_service.clone();
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
              Ok(message) => match message {
                EitherStringOrChatMessage::Left(s) => {
                  if stop_stream.load(std::sync::atomic::Ordering::Relaxed) {
                    trace!("Stop streaming message");
                    break;
                  }
                  let _ = text_sink.send(s).await;
                },
                EitherStringOrChatMessage::Right(answer) => {
                  trace!("Received final answer: {:?}", answer);
                  save_chat_message(
                    user_service.sqlite_connection(uid)?,
                    &chat_id,
                    vec![answer.clone()],
                  )?;

                  let pb = ChatMessagePB::from(answer);
                  send_notification(&chat_id, ChatNotification::DidReceiveChatMessage)
                    .payload(pb)
                    .send();
                  send_notification(&chat_id, ChatNotification::FinishAnswerQuestion).send();
                },
              },
              Err(err) => {
                error!("Failed to stream answer: {}", err);
                let pb = ChatMessageErrorPB {
                  chat_id: chat_id.clone(),
                  error_message: err.to_string(),
                };
                send_notification(&chat_id, ChatNotification::StreamChatMessageError)
                  .payload(pb)
                  .send();
                break;
              },
            }
          }
        },
        Err(err) => {
          let pb = ChatMessageErrorPB {
            chat_id: chat_id.clone(),
            error_message: err.to_string(),
          };
          send_notification(&chat_id, ChatNotification::StreamChatMessageError)
            .payload(pb)
            .send();
        },
      }
      Ok::<(), FlowyError>(())
    });

    let question_pb = ChatMessagePB::from(question);
    Ok(question_pb)
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
        error!("Failed to load previous chat messages: {}", err);
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

  pub async fn get_related_question(
    &self,
    message_id: i64,
  ) -> Result<RepeatedRelatedQuestionPB, FlowyError> {
    let workspace_id = self.user_service.workspace_id()?;
    let resp = self
      .cloud_service
      .get_related_message(&workspace_id, &self.chat_id, message_id)
      .await?;

    trace!(
      "Related messages: chat_id={}, message_id={}, messages:{:?}",
      self.chat_id,
      message_id,
      resp.items
    );
    Ok(RepeatedRelatedQuestionPB::from(resp))
  }

  #[instrument(level = "debug", skip_all, err)]
  pub async fn generate_answer(&self, question_message_id: i64) -> FlowyResult<ChatMessagePB> {
    let workspace_id = self.user_service.workspace_id()?;
    let resp = self
      .cloud_service
      .generate_answer(&workspace_id, &self.chat_id, question_message_id)
      .await?;

    save_answer(
      self.user_service.sqlite_connection(self.uid)?,
      &self.chat_id,
      resp.clone(),
      question_message_id,
    )?;

    let pb = ChatMessagePB::from(resp);
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
      reply_message_id: message.reply_message_id,
    })
    .collect::<Vec<_>>();
  insert_chat_messages(conn, &records)?;
  Ok(())
}
fn save_answer(
  conn: DBConnection,
  chat_id: &str,
  message: ChatMessage,
  question_message_id: i64,
) -> FlowyResult<()> {
  let record = ChatMessageTable {
    message_id: message.message_id,
    chat_id: chat_id.to_string(),
    content: message.content,
    created_at: message.created_at.timestamp(),
    author_type: message.author.author_type as i64,
    author_id: message.author.author_id.to_string(),
    reply_message_id: message.reply_message_id,
  };
  insert_answer_message(conn, question_message_id, record)?;
  Ok(())
}

use crate::chat::Chat;
use crate::entities::{ChatMessageListPB, ChatMessagePB, RepeatedRelatedQuestionPB};
use crate::persistence::{insert_chat, ChatTable};
use dashmap::DashMap;
use flowy_chat_pub::cloud::{
  ChatCloudService, ChatMessage, ChatMessageStream, ChatMessageType, MessageCursor,
  RepeatedChatMessage, RepeatedRelatedQuestion, StreamAnswer,
};
use flowy_error::{FlowyError, FlowyResult};
use flowy_sidecar::manager::SidecarManager;
use flowy_sqlite::DBConnection;
use lib_infra::future::FutureResult;
use lib_infra::util::timestamp;

use std::sync::Arc;
use tracing::trace;

pub trait ChatUserService: Send + Sync + 'static {
  fn user_id(&self) -> Result<i64, FlowyError>;
  fn device_id(&self) -> Result<String, FlowyError>;
  fn workspace_id(&self) -> Result<String, FlowyError>;
  fn sqlite_connection(&self, uid: i64) -> Result<DBConnection, FlowyError>;
}

pub struct ChatManager {
  chat_service: Arc<ChatService>,
  user_service: Arc<dyn ChatUserService>,
  chats: Arc<DashMap<String, Arc<Chat>>>,
}

impl ChatManager {
  pub fn new(
    cloud_service: Arc<dyn ChatCloudService>,
    user_service: impl ChatUserService,
  ) -> ChatManager {
    let sidecar_manager = Arc::new(SidecarManager::new());
    let chat_service = Arc::new(ChatService::new(cloud_service, sidecar_manager));
    let user_service = Arc::new(user_service);

    Self {
      chat_service,
      user_service,
      chats: Arc::new(DashMap::new()),
    }
  }

  pub async fn open_chat(&self, chat_id: &str) -> Result<(), FlowyError> {
    trace!("open chat: {}", chat_id);
    self.chats.entry(chat_id.to_string()).or_insert_with(|| {
      Arc::new(Chat::new(
        self.user_service.user_id().unwrap(),
        chat_id.to_string(),
        self.user_service.clone(),
        self.chat_service.clone(),
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

  pub async fn create_chat(&self, uid: &i64, chat_id: &str) -> Result<Arc<Chat>, FlowyError> {
    let workspace_id = self.user_service.workspace_id()?;
    self
      .chat_service
      .create_chat(uid, &workspace_id, chat_id)
      .await?;
    save_chat(self.user_service.sqlite_connection(*uid)?, chat_id)?;

    let chat = Arc::new(Chat::new(
      self.user_service.user_id().unwrap(),
      chat_id.to_string(),
      self.user_service.clone(),
      self.chat_service.clone(),
    ));
    self.chats.insert(chat_id.to_string(), chat.clone());
    Ok(chat)
  }

  pub async fn stream_chat_message(
    &self,
    chat_id: &str,
    message: &str,
    message_type: ChatMessageType,
    text_stream_port: i64,
  ) -> Result<ChatMessagePB, FlowyError> {
    let chat = self.get_or_create_chat_instance(chat_id).await?;
    let question = chat
      .stream_chat_message(message, message_type, text_stream_port)
      .await?;
    Ok(question)
  }

  pub async fn get_or_create_chat_instance(&self, chat_id: &str) -> Result<Arc<Chat>, FlowyError> {
    let chat = self.chats.get(chat_id).as_deref().cloned();
    match chat {
      None => {
        let chat = Arc::new(Chat::new(
          self.user_service.user_id().unwrap(),
          chat_id.to_string(),
          self.user_service.clone(),
          self.chat_service.clone(),
        ));
        self.chats.insert(chat_id.to_string(), chat.clone());
        Ok(chat)
      },
      Some(chat) => Ok(chat),
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
    let chat = self.get_or_create_chat_instance(chat_id).await?;
    let list = chat
      .load_prev_chat_messages(limit, before_message_id)
      .await?;
    Ok(list)
  }

  pub async fn load_latest_chat_messages(
    &self,
    chat_id: &str,
    limit: i64,
    after_message_id: Option<i64>,
  ) -> Result<ChatMessageListPB, FlowyError> {
    let chat = self.get_or_create_chat_instance(chat_id).await?;
    let list = chat
      .load_latest_chat_messages(limit, after_message_id)
      .await?;
    Ok(list)
  }

  pub async fn get_related_questions(
    &self,
    chat_id: &str,
    message_id: i64,
  ) -> Result<RepeatedRelatedQuestionPB, FlowyError> {
    let chat = self.get_or_create_chat_instance(chat_id).await?;
    let resp = chat.get_related_question(message_id).await?;
    Ok(resp)
  }

  pub async fn generate_answer(
    &self,
    chat_id: &str,
    question_message_id: i64,
  ) -> Result<ChatMessagePB, FlowyError> {
    let chat = self.get_or_create_chat_instance(chat_id).await?;
    let resp = chat.generate_answer(question_message_id).await?;
    Ok(resp)
  }

  pub async fn stop_stream(&self, chat_id: &str) -> Result<(), FlowyError> {
    let chat = self.get_or_create_chat_instance(chat_id).await?;
    chat.stop_stream_message().await;
    Ok(())
  }
}

fn save_chat(conn: DBConnection, chat_id: &str) -> FlowyResult<()> {
  let row = ChatTable {
    chat_id: chat_id.to_string(),
    created_at: timestamp(),
    name: "".to_string(),
    local_model_path: "".to_string(),
    local_model_name: "".to_string(),
    local_enabled: false,
    sync_to_cloud: true,
  };

  insert_chat(conn, &row)?;
  Ok(())
}

pub struct ChatService {
  cloud_service: Arc<dyn ChatCloudService>,
  sidecar_manager: Arc<SidecarManager>,
}

impl ChatService {
  pub fn new(
    cloud_service: Arc<dyn ChatCloudService>,
    sidecar_manager: Arc<SidecarManager>,
  ) -> Self {
    Self {
      cloud_service,
      sidecar_manager,
    }
  }
}

impl ChatCloudService for ChatService {
  fn create_chat(
    &self,
    uid: &i64,
    workspace_id: &str,
    chat_id: &str,
  ) -> FutureResult<(), FlowyError> {
    self.cloud_service.create_chat(uid, workspace_id, chat_id)
  }

  async fn send_chat_message(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message: &str,
    message_type: ChatMessageType,
  ) -> Result<ChatMessageStream, FlowyError> {
    self
      .cloud_service
      .send_chat_message(workspace_id, chat_id, message, message_type)
      .await
  }

  fn send_question(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message: &str,
    message_type: ChatMessageType,
  ) -> FutureResult<ChatMessage, FlowyError> {
    todo!()
  }

  fn save_answer(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message: &str,
    question_id: i64,
  ) -> FutureResult<ChatMessage, FlowyError> {
    todo!()
  }

  async fn stream_answer(
    &self,
    _workspace_id: &str,
    _chat_id: &str,
    _message_id: i64,
  ) -> Result<StreamAnswer, FlowyError> {
    todo!()
  }

  fn get_chat_messages(
    &self,
    workspace_id: &str,
    chat_id: &str,
    offset: MessageCursor,
    limit: u64,
  ) -> FutureResult<RepeatedChatMessage, FlowyError> {
    FutureResult::new(async move {
      Ok(RepeatedChatMessage {
        messages: vec![],
        has_more: false,
        total: 0,
      })
    })
  }

  fn get_related_message(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message_id: i64,
  ) -> FutureResult<RepeatedRelatedQuestion, FlowyError> {
    FutureResult::new(async move {
      Ok(RepeatedRelatedQuestion {
        message_id,
        items: vec![],
      })
    })
  }

  fn generate_answer(
    &self,
    workspace_id: &str,
    chat_id: &str,
    question_message_id: i64,
  ) -> FutureResult<ChatMessage, FlowyError> {
    todo!()
  }
}

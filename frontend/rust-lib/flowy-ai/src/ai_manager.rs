use crate::chat::Chat;
use crate::entities::{
  ChatInfoPB, ChatMessageListPB, ChatMessagePB, FilePB, RepeatedRelatedQuestionPB,
};
use crate::local_ai::local_llm_chat::LocalAIController;
use crate::middleware::chat_service_mw::AICloudServiceMiddleware;
use crate::persistence::{insert_chat, read_chat_metadata, ChatTable};

use appflowy_plugin::manager::PluginManager;
use dashmap::DashMap;
use flowy_ai_pub::cloud::{ChatCloudService, ChatMessageMetadata, ChatMessageType};
use flowy_error::{FlowyError, FlowyResult};
use flowy_sqlite::kv::KVStorePreferences;
use flowy_sqlite::DBConnection;

use flowy_storage_pub::storage::StorageService;
use lib_infra::util::timestamp;
use std::path::PathBuf;
use std::sync::{Arc, Weak};
use tracing::{info, trace};

pub trait AIUserService: Send + Sync + 'static {
  fn user_id(&self) -> Result<i64, FlowyError>;
  fn device_id(&self) -> Result<String, FlowyError>;
  fn workspace_id(&self) -> Result<String, FlowyError>;
  fn sqlite_connection(&self, uid: i64) -> Result<DBConnection, FlowyError>;
  fn application_root_dir(&self) -> Result<PathBuf, FlowyError>;
}

pub struct AIManager {
  pub cloud_service_wm: Arc<AICloudServiceMiddleware>,
  pub user_service: Arc<dyn AIUserService>,
  chats: Arc<DashMap<String, Arc<Chat>>>,
  pub local_ai_controller: Arc<LocalAIController>,
}

impl AIManager {
  pub fn new(
    chat_cloud_service: Arc<dyn ChatCloudService>,
    user_service: impl AIUserService,
    store_preferences: Arc<KVStorePreferences>,
    storage_service: Weak<dyn StorageService>,
  ) -> AIManager {
    let user_service = Arc::new(user_service);
    let plugin_manager = Arc::new(PluginManager::new());
    let local_ai_controller = Arc::new(LocalAIController::new(
      plugin_manager.clone(),
      store_preferences.clone(),
      user_service.clone(),
      chat_cloud_service.clone(),
    ));

    // setup local chat service
    let cloud_service_wm = Arc::new(AICloudServiceMiddleware::new(
      user_service.clone(),
      chat_cloud_service,
      local_ai_controller.clone(),
      storage_service,
    ));

    Self {
      cloud_service_wm,
      user_service,
      chats: Arc::new(DashMap::new()),
      local_ai_controller,
    }
  }

  pub async fn initialize(&self, _workspace_id: &str) -> Result<(), FlowyError> {
    // Ignore following error
    let _ = self.local_ai_controller.refresh().await;
    Ok(())
  }

  pub async fn open_chat(&self, chat_id: &str) -> Result<(), FlowyError> {
    trace!("open chat: {}", chat_id);
    self.chats.entry(chat_id.to_string()).or_insert_with(|| {
      Arc::new(Chat::new(
        self.user_service.user_id().unwrap(),
        chat_id.to_string(),
        self.user_service.clone(),
        self.cloud_service_wm.clone(),
      ))
    });

    trace!("[AI Plugin] notify open chat: {}", chat_id);
    if self.local_ai_controller.is_running() {
      self.local_ai_controller.open_chat(chat_id);
    }
    Ok(())
  }

  pub async fn close_chat(&self, chat_id: &str) -> Result<(), FlowyError> {
    trace!("close chat: {}", chat_id);
    self.local_ai_controller.close_chat(chat_id);
    Ok(())
  }

  pub async fn delete_chat(&self, chat_id: &str) -> Result<(), FlowyError> {
    if let Some((_, chat)) = self.chats.remove(chat_id) {
      chat.close();

      if self.local_ai_controller.is_running() {
        info!("[AI Plugin] notify close chat: {}", chat_id);
        self.local_ai_controller.close_chat(chat_id);
      }
    }
    Ok(())
  }

  pub async fn get_chat_info(&self, chat_id: &str) -> FlowyResult<ChatInfoPB> {
    let mut conn = self.user_service.sqlite_connection(0)?;
    let metadata = read_chat_metadata(&mut conn, chat_id)?;
    let files = metadata
      .files
      .into_iter()
      .map(|file| FilePB {
        id: file.id,
        name: file.name,
      })
      .collect();

    Ok(ChatInfoPB {
      chat_id: chat_id.to_string(),
      files,
    })
  }

  pub async fn create_chat(&self, uid: &i64, chat_id: &str) -> Result<Arc<Chat>, FlowyError> {
    let workspace_id = self.user_service.workspace_id()?;
    self
      .cloud_service_wm
      .create_chat(uid, &workspace_id, chat_id)
      .await?;
    save_chat(self.user_service.sqlite_connection(*uid)?, chat_id)?;

    let chat = Arc::new(Chat::new(
      self.user_service.user_id().unwrap(),
      chat_id.to_string(),
      self.user_service.clone(),
      self.cloud_service_wm.clone(),
    ));
    self.chats.insert(chat_id.to_string(), chat.clone());
    Ok(chat)
  }

  pub async fn stream_chat_message(
    &self,
    chat_id: &str,
    message: &str,
    message_type: ChatMessageType,
    answer_stream_port: i64,
    question_stream_port: i64,
    metadata: Vec<ChatMessageMetadata>,
  ) -> Result<ChatMessagePB, FlowyError> {
    let chat = self.get_or_create_chat_instance(chat_id).await?;
    let question = chat
      .stream_chat_message(
        message,
        message_type,
        answer_stream_port,
        question_stream_port,
        metadata,
      )
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
          self.cloud_service_wm.clone(),
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

  pub async fn chat_with_file(&self, chat_id: &str, file_path: PathBuf) -> FlowyResult<()> {
    let chat = self.get_or_create_chat_instance(chat_id).await?;
    chat.index_file(file_path).await?;
    Ok(())
  }

  pub fn local_ai_purchased(&self) {}
}

fn save_chat(conn: DBConnection, chat_id: &str) -> FlowyResult<()> {
  let row = ChatTable {
    chat_id: chat_id.to_string(),
    created_at: timestamp(),
    name: "".to_string(),
    local_files: "".to_string(),
    metadata: "".to_string(),
    local_enabled: false,
    sync_to_cloud: false,
  };

  insert_chat(conn, &row)?;
  Ok(())
}

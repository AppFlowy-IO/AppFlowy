use crate::chat::Chat;
use crate::entities::{ChatMessageListPB, ChatMessagePB, RepeatedRelatedQuestionPB};
use crate::persistence::{insert_chat, select_single_message, ChatTable};
use dashmap::DashMap;
use flowy_chat_pub::cloud::{
  ChatCloudService, ChatMessage, ChatMessageType, CompletionType, MessageCursor,
  RepeatedChatMessage, RepeatedRelatedQuestion, StreamAnswer, StreamComplete,
};
use flowy_error::{FlowyError, FlowyResult};
use flowy_sidecar::manager::SidecarManager;
use flowy_sqlite::DBConnection;
use lib_infra::future::FutureResult;
use lib_infra::util::timestamp;

use crate::local_ai::manager::{LocalAIManager, LocalAISetting};
use flowy_sqlite::kv::KVStorePreferences;
use lib_infra::async_trait::async_trait;
use parking_lot::RwLock;

use futures::{StreamExt, TryStreamExt};
use std::sync::Arc;
use tracing::{error, info, trace};

pub trait ChatUserService: Send + Sync + 'static {
  fn user_id(&self) -> Result<i64, FlowyError>;
  fn device_id(&self) -> Result<String, FlowyError>;
  fn workspace_id(&self) -> Result<String, FlowyError>;
  fn sqlite_connection(&self, uid: i64) -> Result<DBConnection, FlowyError>;
}

pub struct ChatManager {
  pub chat_service: Arc<ChatService>,
  pub user_service: Arc<dyn ChatUserService>,
  chats: Arc<DashMap<String, Arc<Chat>>>,
  store_preferences: Arc<KVStorePreferences>,
}

const LOCAL_AI_SETTING_KEY: &str = "local_ai_setting";
impl ChatManager {
  pub fn new(
    cloud_service: Arc<dyn ChatCloudService>,
    user_service: impl ChatUserService,
    store_preferences: Arc<KVStorePreferences>,
  ) -> ChatManager {
    let user_service = Arc::new(user_service);
    let local_ai_setting = store_preferences
      .get_object::<LocalAISetting>(LOCAL_AI_SETTING_KEY)
      .unwrap_or_default();
    let sidecar_manager = Arc::new(SidecarManager::new());

    // setup local AI chat plugin
    let local_ai_manager = Arc::new(LocalAIManager::new(sidecar_manager));
    // setup local chat service
    let chat_service = Arc::new(ChatService::new(
      user_service.clone(),
      cloud_service,
      local_ai_manager,
      local_ai_setting,
    ));

    Self {
      chat_service,
      user_service,
      chats: Arc::new(DashMap::new()),
      store_preferences,
    }
  }

  pub fn update_local_ai_setting(&self, setting: LocalAISetting) -> FlowyResult<()> {
    self.chat_service.update_local_ai_setting(setting.clone())?;
    self
      .store_preferences
      .set_object(LOCAL_AI_SETTING_KEY, setting)?;
    Ok(())
  }

  pub fn get_local_ai_setting(&self) -> FlowyResult<LocalAISetting> {
    let setting = self.chat_service.local_ai_setting.read().clone();
    Ok(setting)
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

fn setup_local_ai(local_ai_setting: &LocalAISetting, local_ai_manager: Arc<LocalAIManager>) {
  trace!(
    "[Chat Plugin] update local ai setting: {:?}",
    local_ai_setting
  );

  if let Ok(config) = local_ai_setting.get_chat_plugin_config() {
    tokio::spawn(async move {
      match local_ai_manager.setup_chat_plugin(config).await {
        Ok(_) => {
          info!("Local AI chat plugin setup successfully");
        },
        Err(err) => {
          error!("Failed to setup local AI chat plugin: {:?}", err);
        },
      }
    });
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
  pub cloud_service: Arc<dyn ChatCloudService>,
  user_service: Arc<dyn ChatUserService>,
  local_ai_manager: Arc<LocalAIManager>,
  local_ai_setting: Arc<RwLock<LocalAISetting>>,
}

impl ChatService {
  pub fn new(
    user_service: Arc<dyn ChatUserService>,
    cloud_service: Arc<dyn ChatCloudService>,
    local_ai_manager: Arc<LocalAIManager>,
    local_ai_setting: LocalAISetting,
  ) -> Self {
    setup_local_ai(&local_ai_setting, local_ai_manager.clone());

    Self {
      user_service,
      cloud_service,
      local_ai_manager,
      local_ai_setting: Arc::new(RwLock::new(local_ai_setting)),
    }
  }

  pub fn update_local_ai_setting(&self, setting: LocalAISetting) -> FlowyResult<()> {
    setting.validate()?;
    setup_local_ai(&setting, self.local_ai_manager.clone());
    *self.local_ai_setting.write() = setting;
    Ok(())
  }

  fn get_message_content(&self, message_id: i64) -> FlowyResult<String> {
    let uid = self.user_service.user_id()?;
    let conn = self.user_service.sqlite_connection(uid)?;
    let content = select_single_message(conn, message_id)?
      .map(|data| data.content)
      .ok_or_else(|| {
        FlowyError::record_not_found().with_context(format!("Message not found: {}", message_id))
      })?;

    Ok(content)
  }
}

#[async_trait]
impl ChatCloudService for ChatService {
  fn create_chat(
    &self,
    uid: &i64,
    workspace_id: &str,
    chat_id: &str,
  ) -> FutureResult<(), FlowyError> {
    self.cloud_service.create_chat(uid, workspace_id, chat_id)
  }

  fn save_question(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message: &str,
    message_type: ChatMessageType,
  ) -> FutureResult<ChatMessage, FlowyError> {
    self
      .cloud_service
      .save_question(workspace_id, chat_id, message, message_type)
  }

  fn save_answer(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message: &str,
    question_id: i64,
  ) -> FutureResult<ChatMessage, FlowyError> {
    self
      .cloud_service
      .save_answer(workspace_id, chat_id, message, question_id)
  }

  async fn ask_question(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message_id: i64,
  ) -> Result<StreamAnswer, FlowyError> {
    if self.local_ai_setting.read().enabled {
      let content = self.get_message_content(message_id)?;
      let stream = self
        .local_ai_manager
        .ask_question(chat_id, &content)
        .await?
        .map_err(FlowyError::from);
      Ok(stream.boxed())
    } else {
      self
        .cloud_service
        .ask_question(workspace_id, chat_id, message_id)
        .await
    }
  }

  async fn generate_answer(
    &self,
    workspace_id: &str,
    chat_id: &str,
    question_message_id: i64,
  ) -> Result<ChatMessage, FlowyError> {
    if self.local_ai_setting.read().enabled {
      let content = self.get_message_content(question_message_id)?;
      let _answer = self
        .local_ai_manager
        .generate_answer(chat_id, &content)
        .await?;
      todo!()
    } else {
      self
        .cloud_service
        .generate_answer(workspace_id, chat_id, question_message_id)
        .await
    }
  }

  fn get_chat_messages(
    &self,
    workspace_id: &str,
    chat_id: &str,
    offset: MessageCursor,
    limit: u64,
  ) -> FutureResult<RepeatedChatMessage, FlowyError> {
    self
      .cloud_service
      .get_chat_messages(workspace_id, chat_id, offset, limit)
  }

  fn get_related_message(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message_id: i64,
  ) -> FutureResult<RepeatedRelatedQuestion, FlowyError> {
    if self.local_ai_setting.read().enabled {
      FutureResult::new(async move {
        Ok(RepeatedRelatedQuestion {
          message_id,
          items: vec![],
        })
      })
    } else {
      self
        .cloud_service
        .get_related_message(workspace_id, chat_id, message_id)
    }
  }

  async fn stream_complete(
    &self,
    workspace_id: &str,
    text: &str,
    complete_type: CompletionType,
  ) -> Result<StreamComplete, FlowyError> {
    if self.local_ai_setting.read().enabled {
      todo!()
    } else {
      self
        .stream_complete(workspace_id, text, complete_type)
        .await
    }
  }
}

use crate::chat::Chat;
use crate::entities::{
  AIModelPB, ChatInfoPB, ChatMessageListPB, ChatMessagePB, ChatSettingsPB, FilePB,
  ModelSelectionPB, PredefinedFormatPB, RepeatedRelatedQuestionPB, StreamMessageParams,
};
use crate::local_ai::controller::{LocalAIController, LocalAISetting};
use crate::middleware::chat_service_mw::ChatServiceMiddleware;
use flowy_ai_pub::persistence::read_chat_metadata;
use std::collections::HashMap;

use dashmap::DashMap;
use flowy_ai_pub::cloud::{AIModel, ChatCloudService, ChatSettings, UpdateChatParams};
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_sqlite::kv::KVStorePreferences;

use crate::model_select::{
  LocalAiSource, LocalModelStorageImpl, ModelSelectionControl, ServerAiSource,
  ServerModelStorageImpl, SourceKey, GLOBAL_ACTIVE_MODEL_KEY,
};
use crate::notification::{chat_notification_builder, ChatNotification};
use flowy_ai_pub::persistence::{
  batch_insert_collab_metadata, batch_select_collab_metadata, AFCollabMetadata,
};
use flowy_ai_pub::user_service::AIUserService;
use flowy_storage_pub::storage::StorageService;
use lib_infra::async_trait::async_trait;
use serde_json::json;
use std::path::PathBuf;
use std::str::FromStr;
use std::sync::{Arc, Weak};
use tokio::sync::Mutex;
use tracing::{error, info, instrument, trace};
use uuid::Uuid;

/// AIExternalService is an interface for external services that AI plugin can interact with.
#[async_trait]
pub trait AIExternalService: Send + Sync + 'static {
  async fn query_chat_rag_ids(
    &self,
    parent_view_id: &Uuid,
    chat_id: &Uuid,
  ) -> Result<Vec<Uuid>, FlowyError>;

  async fn sync_rag_documents(
    &self,
    workspace_id: &Uuid,
    rag_ids: Vec<Uuid>,
    rag_metadata_map: HashMap<Uuid, AFCollabMetadata>,
  ) -> Result<Vec<AFCollabMetadata>, FlowyError>;

  async fn notify_did_send_message(&self, chat_id: &Uuid, message: &str) -> Result<(), FlowyError>;
}

pub struct AIManager {
  pub cloud_service_wm: Arc<ChatServiceMiddleware>,
  pub user_service: Arc<dyn AIUserService>,
  pub external_service: Arc<dyn AIExternalService>,
  chats: Arc<DashMap<Uuid, Arc<Chat>>>,
  pub local_ai: Arc<LocalAIController>,
  pub store_preferences: Arc<KVStorePreferences>,
  model_control: Mutex<ModelSelectionControl>,
}
impl Drop for AIManager {
  fn drop(&mut self) {
    tracing::trace!("[Drop] drop ai manager");
  }
}

impl AIManager {
  pub fn new(
    chat_cloud_service: Arc<dyn ChatCloudService>,
    user_service: impl AIUserService,
    store_preferences: Arc<KVStorePreferences>,
    storage_service: Weak<dyn StorageService>,
    query_service: impl AIExternalService,
    local_ai: Arc<LocalAIController>,
  ) -> AIManager {
    let user_service = Arc::new(user_service);
    let cloned_local_ai = local_ai.clone();
    tokio::spawn(async move {
      cloned_local_ai.observe_plugin_resource().await;
    });

    let external_service = Arc::new(query_service);
    let cloud_service_wm = Arc::new(ChatServiceMiddleware::new(
      user_service.clone(),
      chat_cloud_service,
      local_ai.clone(),
      storage_service,
    ));
    let mut model_control = ModelSelectionControl::new();
    model_control.set_local_storage(LocalModelStorageImpl(store_preferences.clone()));
    model_control.set_server_storage(ServerModelStorageImpl(cloud_service_wm.clone()));
    model_control.add_source(Box::new(ServerAiSource::new(cloud_service_wm.clone())));

    Self {
      cloud_service_wm,
      user_service,
      chats: Arc::new(DashMap::new()),
      local_ai,
      external_service,
      store_preferences,
      model_control: Mutex::new(model_control),
    }
  }

  async fn reload_with_workspace_id(&self, workspace_id: &Uuid) {
    // Check if local AI is enabled for this workspace and if we're in local mode
    let result = self.user_service.is_local_model().await;
    if let Err(err) = &result {
      if matches!(err.code, ErrorCode::UserNotLogin) {
        info!("[AI Manager] User not logged in, skipping local AI reload");
        return;
      }
    }

    let is_local = result.unwrap_or(false);
    let is_enabled = self
      .local_ai
      .is_enabled_on_workspace(&workspace_id.to_string());
    let is_running = self.local_ai.is_running();
    info!(
      "[AI Manager] Reloading workspace: {}, is_local: {}, is_enabled: {}, is_running: {}",
      workspace_id, is_local, is_enabled, is_running
    );

    // Shutdown AI if it's running but shouldn't be (not enabled and not in local mode)
    if is_running && !is_enabled && !is_local {
      info!("[AI Manager] Local AI is running but not enabled, shutting it down");
      let local_ai = self.local_ai.clone();
      tokio::spawn(async move {
        if let Err(err) = local_ai.toggle_plugin(false).await {
          error!("[AI Manager] failed to shutdown local AI: {:?}", err);
        }
      });
      return;
    }

    // Start AI if it's enabled but not running
    if is_enabled && !is_running {
      info!("[AI Manager] Local AI is enabled but not running, starting it now");
      let local_ai = self.local_ai.clone();
      tokio::spawn(async move {
        if let Err(err) = local_ai.toggle_plugin(true).await {
          error!("[AI Manager] failed to start local AI: {:?}", err);
        }
      });
      return;
    }

    // Log status for other cases
    if is_running {
      info!("[AI Manager] Local AI is already running");
    }
  }

  #[instrument(skip_all, err)]
  pub async fn on_launch_if_authenticated(&self, workspace_id: &Uuid) -> Result<(), FlowyError> {
    let is_enabled = self
      .local_ai
      .is_enabled_on_workspace(&workspace_id.to_string());

    info!("local is enabled: {}", is_enabled);
    if is_enabled {
      self
        .local_ai
        .reload_ollama_client(&workspace_id.to_string());
      self
        .model_control
        .lock()
        .await
        .add_source(Box::new(LocalAiSource::new(self.local_ai.clone())));
    } else {
      self.model_control.lock().await.remove_local_source();
    }

    self.reload_with_workspace_id(workspace_id).await;
    Ok(())
  }

  pub async fn initialize_after_sign_in(&self, workspace_id: &Uuid) -> Result<(), FlowyError> {
    self.on_launch_if_authenticated(workspace_id).await?;
    Ok(())
  }

  pub async fn initialize_after_sign_up(&self, workspace_id: &Uuid) -> Result<(), FlowyError> {
    self.on_launch_if_authenticated(workspace_id).await?;
    Ok(())
  }

  #[instrument(skip_all, err)]
  pub async fn initialize_after_open_workspace(
    &self,
    workspace_id: &Uuid,
  ) -> Result<(), FlowyError> {
    self.on_launch_if_authenticated(workspace_id).await?;
    Ok(())
  }

  pub async fn open_chat(&self, chat_id: &Uuid) -> Result<(), FlowyError> {
    self.chats.entry(*chat_id).or_insert_with(|| {
      Arc::new(Chat::new(
        self.user_service.user_id().unwrap(),
        *chat_id,
        self.user_service.clone(),
        self.cloud_service_wm.clone(),
      ))
    });
    if self.local_ai.is_running() {
      trace!("[AI Plugin] notify open chat: {}", chat_id);
      self.local_ai.open_chat(chat_id);
    }

    let user_service = self.user_service.clone();
    let cloud_service_wm = self.cloud_service_wm.clone();
    let store_preferences = self.store_preferences.clone();
    let external_service = self.external_service.clone();
    let chat_id = *chat_id;
    tokio::spawn(async move {
      match refresh_chat_setting(
        &user_service,
        &cloud_service_wm,
        &store_preferences,
        &chat_id,
      )
      .await
      {
        Ok(settings) => {
          let rag_ids = settings
            .rag_ids
            .into_iter()
            .flat_map(|r| Uuid::from_str(&r).ok())
            .collect();
          let _ = sync_chat_documents(user_service, external_service, rag_ids).await;
        },
        Err(err) => {
          error!("failed to refresh chat settings: {}", err);
        },
      }
    });

    Ok(())
  }

  pub async fn close_chat(&self, chat_id: &Uuid) -> Result<(), FlowyError> {
    trace!("close chat: {}", chat_id);
    self.local_ai.close_chat(chat_id);
    Ok(())
  }

  pub async fn delete_chat(&self, chat_id: &Uuid) -> Result<(), FlowyError> {
    if let Some((_, chat)) = self.chats.remove(chat_id) {
      chat.close();

      if self.local_ai.is_running() {
        info!("[AI Plugin] notify close chat: {}", chat_id);
        self.local_ai.close_chat(chat_id);
      }
    }
    Ok(())
  }

  pub async fn get_chat_info(&self, chat_id: &str) -> FlowyResult<ChatInfoPB> {
    let uid = self.user_service.user_id()?;
    let mut conn = self.user_service.sqlite_connection(uid)?;
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

  pub async fn create_chat(
    &self,
    uid: &i64,
    parent_view_id: &Uuid,
    chat_id: &Uuid,
  ) -> Result<Arc<Chat>, FlowyError> {
    let workspace_id = self.user_service.workspace_id()?;
    let rag_ids = self
      .external_service
      .query_chat_rag_ids(parent_view_id, chat_id)
      .await
      .unwrap_or_default();
    info!("[Chat] create chat with rag_ids: {:?}", rag_ids);

    self
      .cloud_service_wm
      .create_chat(uid, &workspace_id, chat_id, rag_ids, "", json!({}))
      .await?;

    let chat = Arc::new(Chat::new(
      self.user_service.user_id()?,
      *chat_id,
      self.user_service.clone(),
      self.cloud_service_wm.clone(),
    ));
    self.chats.insert(*chat_id, chat.clone());
    Ok(chat)
  }

  pub async fn stream_chat_message(
    &self,
    params: StreamMessageParams,
  ) -> Result<ChatMessagePB, FlowyError> {
    let chat = self.get_or_create_chat_instance(&params.chat_id).await?;
    let ai_model = self.get_active_model(&params.chat_id.to_string()).await;
    let question = chat.stream_chat_message(&params, Some(ai_model)).await?;
    let _ = self
      .external_service
      .notify_did_send_message(&params.chat_id, &params.message)
      .await;
    Ok(question)
  }

  pub async fn stream_regenerate_response(
    &self,
    chat_id: &Uuid,
    answer_message_id: i64,
    answer_stream_port: i64,
    format: Option<PredefinedFormatPB>,
    model: Option<AIModelPB>,
  ) -> FlowyResult<()> {
    let chat = self.get_or_create_chat_instance(chat_id).await?;
    let question_message_id = chat
      .get_question_id_from_answer_id(chat_id, answer_message_id)
      .await?;

    let model = match model {
      None => self.get_active_model(&chat_id.to_string()).await,
      Some(model) => model.into(),
    };
    chat
      .stream_regenerate_response(question_message_id, answer_stream_port, format, Some(model))
      .await?;
    Ok(())
  }

  pub async fn update_local_ai_setting(&self, setting: LocalAISetting) -> FlowyResult<()> {
    let workspace_id = self.user_service.workspace_id()?;
    let old_settings = self.local_ai.get_local_ai_setting();
    // Only restart if the server URL has changed and local AI is not running
    let need_restart =
      old_settings.ollama_server_url != setting.ollama_server_url && !self.local_ai.is_running();

    // Update settings first
    self
      .local_ai
      .update_local_ai_setting(setting.clone())
      .await?;

    // Handle model change if needed
    info!(
      "[AI Plugin] update global active model, previous: {}, current: {}",
      old_settings.chat_model_name, setting.chat_model_name
    );
    let model = AIModel::local(setting.chat_model_name, "".to_string());
    self
      .update_selected_model(GLOBAL_ACTIVE_MODEL_KEY.to_string(), model)
      .await?;

    if need_restart {
      self
        .local_ai
        .reload_ollama_client(&workspace_id.to_string());
      self.local_ai.restart_plugin().await;
    }

    Ok(())
  }

  #[instrument(skip_all, level = "debug")]
  pub async fn update_selected_model(&self, source: String, model: AIModel) -> FlowyResult<()> {
    let workspace_id = self.user_service.workspace_id()?;
    let source_key = SourceKey::new(source.clone());
    self
      .model_control
      .lock()
      .await
      .set_active_model(&workspace_id, &source_key, model.clone())
      .await?;

    info!(
      "[Model Selection] selected model: {:?} for key:{}",
      model,
      source_key.storage_id()
    );
    chat_notification_builder(&source, ChatNotification::DidUpdateSelectedModel)
      .payload(AIModelPB::from(model))
      .send();
    Ok(())
  }

  #[instrument(skip_all, level = "debug")]
  pub async fn toggle_local_ai(&self) -> FlowyResult<()> {
    let enabled = self.local_ai.toggle_local_ai().await?;
    if enabled {
      self
        .model_control
        .lock()
        .await
        .add_source(Box::new(LocalAiSource::new(self.local_ai.clone())));

      if let Some(name) = self.local_ai.get_plugin_chat_model() {
        let model = AIModel::local(name, "".to_string());
        info!("Set global active model to local ai: {}", model.name);
        self
          .update_selected_model(GLOBAL_ACTIVE_MODEL_KEY.to_string(), model)
          .await?;
      }
    } else {
      self.model_control.lock().await.remove_local_source();
    }

    Ok(())
  }

  pub async fn get_active_model(&self, source: &str) -> AIModel {
    match self.user_service.workspace_id() {
      Ok(workspace_id) => {
        let source_key = SourceKey::new(source.to_string());
        self
          .model_control
          .lock()
          .await
          .get_active_model(&workspace_id, &source_key)
          .await
      },
      Err(_) => AIModel::default(),
    }
  }

  pub async fn get_local_available_models(&self) -> FlowyResult<ModelSelectionPB> {
    let setting = self.local_ai.get_local_ai_setting();
    let workspace_id = self.user_service.workspace_id()?;
    let mut models = self
      .model_control
      .lock()
      .await
      .get_local_models(&workspace_id)
      .await;

    let selected_model = AIModel::local(setting.chat_model_name, "".to_string());
    if models.is_empty() {
      models.push(selected_model.clone());
    }

    Ok(ModelSelectionPB {
      models: models.into_iter().map(AIModelPB::from).collect(),
      selected_model: AIModelPB::from(selected_model),
    })
  }

  pub async fn get_available_models(
    &self,
    source: String,
    setting_only: bool,
  ) -> FlowyResult<ModelSelectionPB> {
    let is_local_mode = self.user_service.is_local_model().await?;
    if is_local_mode {
      return self.get_local_available_models().await;
    }

    let workspace_id = self.user_service.workspace_id()?;
    let local_model_name = if setting_only {
      Some(self.local_ai.get_local_ai_setting().chat_model_name)
    } else {
      None
    };

    let source_key = SourceKey::new(source);
    let model_control = self.model_control.lock().await;
    let active_model = model_control
      .get_active_model(&workspace_id, &source_key)
      .await;
    let all_models = model_control
      .get_models_with_specific_local_model(&workspace_id, local_model_name)
      .await;
    drop(model_control);

    Ok(ModelSelectionPB {
      models: all_models.into_iter().map(AIModelPB::from).collect(),
      selected_model: AIModelPB::from(active_model),
    })
  }

  pub async fn get_or_create_chat_instance(&self, chat_id: &Uuid) -> Result<Arc<Chat>, FlowyError> {
    let chat = self.chats.get(chat_id).as_deref().cloned();
    match chat {
      None => {
        let chat = Arc::new(Chat::new(
          self.user_service.user_id()?,
          *chat_id,
          self.user_service.clone(),
          self.cloud_service_wm.clone(),
        ));
        self.chats.insert(*chat_id, chat.clone());
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
    chat_id: &Uuid,
    limit: u64,
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
    chat_id: &Uuid,
    limit: u64,
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
    chat_id: &Uuid,
    message_id: i64,
  ) -> Result<RepeatedRelatedQuestionPB, FlowyError> {
    let chat = self.get_or_create_chat_instance(chat_id).await?;
    let ai_model = self.get_active_model(&chat_id.to_string()).await;
    let resp = chat
      .get_related_question(message_id, Some(ai_model))
      .await?;
    Ok(resp)
  }

  pub async fn generate_answer(
    &self,
    chat_id: &Uuid,
    question_message_id: i64,
  ) -> Result<ChatMessagePB, FlowyError> {
    let chat = self.get_or_create_chat_instance(chat_id).await?;
    let resp = chat.generate_answer(question_message_id).await?;
    Ok(resp)
  }

  pub async fn stop_stream(&self, chat_id: &Uuid) -> Result<(), FlowyError> {
    let chat = self.get_or_create_chat_instance(chat_id).await?;
    chat.stop_stream_message().await;
    Ok(())
  }

  pub async fn chat_with_file(&self, chat_id: &Uuid, file_path: PathBuf) -> FlowyResult<()> {
    let chat = self.get_or_create_chat_instance(chat_id).await?;
    chat.index_file(file_path).await?;
    Ok(())
  }

  pub async fn get_rag_ids(&self, chat_id: &Uuid) -> FlowyResult<Vec<String>> {
    if let Some(settings) = self
      .store_preferences
      .get_object::<ChatSettings>(&setting_store_key(chat_id))
    {
      return Ok(settings.rag_ids);
    }

    let settings = refresh_chat_setting(
      &self.user_service,
      &self.cloud_service_wm,
      &self.store_preferences,
      chat_id,
    )
    .await?;
    Ok(settings.rag_ids)
  }

  pub async fn update_rag_ids(&self, chat_id: &Uuid, rag_ids: Vec<String>) -> FlowyResult<()> {
    info!("[Chat] update chat:{} rag ids: {:?}", chat_id, rag_ids);
    let workspace_id = self.user_service.workspace_id()?;
    let update_setting = UpdateChatParams {
      name: None,
      metadata: None,
      rag_ids: Some(rag_ids.clone()),
    };
    self
      .cloud_service_wm
      .update_chat_settings(&workspace_id, chat_id, update_setting)
      .await?;

    let chat_setting_store_key = setting_store_key(chat_id);
    if let Some(settings) = self
      .store_preferences
      .get_object::<ChatSettings>(&chat_setting_store_key)
    {
      if let Err(err) = self.store_preferences.set_object(
        &chat_setting_store_key,
        &ChatSettings {
          rag_ids: rag_ids.clone(),
          ..settings
        },
      ) {
        error!("failed to set chat settings: {}", err);
      }
    }

    let user_service = self.user_service.clone();
    let external_service = self.external_service.clone();
    let rag_ids = rag_ids
      .into_iter()
      .flat_map(|r| Uuid::from_str(&r).ok())
      .collect();
    sync_chat_documents(user_service, external_service, rag_ids).await?;
    Ok(())
  }
}

async fn sync_chat_documents(
  user_service: Arc<dyn AIUserService>,
  external_service: Arc<dyn AIExternalService>,
  rag_ids: Vec<Uuid>,
) -> FlowyResult<()> {
  if rag_ids.is_empty() {
    return Ok(());
  }

  let uid = user_service.user_id()?;
  let conn = user_service.sqlite_connection(uid)?;
  let metadata_map = batch_select_collab_metadata(conn, &rag_ids)?;

  let user_service = user_service.clone();
  tokio::spawn(async move {
    if let Ok(workspace_id) = user_service.workspace_id() {
      if let Ok(metadatas) = external_service
        .sync_rag_documents(&workspace_id, rag_ids, metadata_map)
        .await
      {
        if let Ok(uid) = user_service.user_id() {
          if let Ok(conn) = user_service.sqlite_connection(uid) {
            info!("sync rag documents success: {}", metadatas.len());
            batch_insert_collab_metadata(conn, &metadatas).unwrap();
          }
        }
      }
    }
  });

  Ok(())
}

async fn refresh_chat_setting(
  user_service: &Arc<dyn AIUserService>,
  cloud_service: &Arc<ChatServiceMiddleware>,
  store_preferences: &Arc<KVStorePreferences>,
  chat_id: &Uuid,
) -> FlowyResult<ChatSettings> {
  info!("[Chat] refresh chat:{} setting", chat_id);
  let workspace_id = user_service.workspace_id()?;
  let settings = cloud_service
    .get_chat_settings(&workspace_id, chat_id)
    .await?;

  if let Err(err) = store_preferences.set_object(&setting_store_key(chat_id), &settings) {
    error!("failed to set chat settings: {}", err);
  }

  chat_notification_builder(chat_id.to_string(), ChatNotification::DidUpdateChatSettings)
    .payload(ChatSettingsPB {
      rag_ids: settings.rag_ids.clone(),
    })
    .send();

  Ok(settings)
}

fn setting_store_key(chat_id: &Uuid) -> String {
  format!("chat_settings_{}", chat_id)
}

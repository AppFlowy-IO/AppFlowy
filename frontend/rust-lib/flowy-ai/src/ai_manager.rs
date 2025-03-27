use crate::chat::Chat;
use crate::entities::{
  AIModelPB, AvailableModelsPB, ChatInfoPB, ChatMessageListPB, ChatMessagePB, ChatSettingsPB,
  FilePB, PredefinedFormatPB, RepeatedRelatedQuestionPB, StreamMessageParams,
};
use crate::local_ai::controller::LocalAIController;
use crate::middleware::chat_service_mw::AICloudServiceMiddleware;
use crate::persistence::{insert_chat, read_chat_metadata, ChatTable};
use std::collections::HashMap;

use af_plugin::manager::PluginManager;
use dashmap::DashMap;
use flowy_ai_pub::cloud::{AIModel, ChatCloudService, ChatSettings, UpdateChatParams};
use flowy_error::{FlowyError, FlowyResult};
use flowy_sqlite::kv::KVStorePreferences;
use flowy_sqlite::DBConnection;

use crate::notification::{chat_notification_builder, ChatNotification};
use crate::util::ai_available_models_key;
use collab_integrate::persistence::collab_metadata_sql::{
  batch_insert_collab_metadata, batch_select_collab_metadata, AFCollabMetadata,
};
use flowy_ai_pub::cloud::ai_dto::AvailableModel;
use flowy_storage_pub::storage::StorageService;
use lib_infra::async_trait::async_trait;
use lib_infra::util::timestamp;
use std::path::PathBuf;
use std::sync::{Arc, Weak};
use tokio::sync::RwLock;
use tracing::{error, info, instrument, trace};

pub trait AIUserService: Send + Sync + 'static {
  fn user_id(&self) -> Result<i64, FlowyError>;
  fn device_id(&self) -> Result<String, FlowyError>;
  fn workspace_id(&self) -> Result<String, FlowyError>;
  fn sqlite_connection(&self, uid: i64) -> Result<DBConnection, FlowyError>;
  fn application_root_dir(&self) -> Result<PathBuf, FlowyError>;
}

/// AIExternalService is an interface for external services that AI plugin can interact with.
#[async_trait]
pub trait AIExternalService: Send + Sync + 'static {
  async fn query_chat_rag_ids(
    &self,
    parent_view_id: &str,
    chat_id: &str,
  ) -> Result<Vec<String>, FlowyError>;

  async fn sync_rag_documents(
    &self,
    workspace_id: &str,
    rag_ids: Vec<String>,
    rag_metadata_map: HashMap<String, AFCollabMetadata>,
  ) -> Result<Vec<AFCollabMetadata>, FlowyError>;

  async fn notify_did_send_message(&self, chat_id: &str, message: &str) -> Result<(), FlowyError>;
}

#[derive(Debug, Default)]
struct ServerModelsCache {
  models: Vec<AvailableModel>,
  timestamp: Option<i64>,
}

pub const GLOBAL_ACTIVE_MODEL_KEY: &str = "global_active_model";

pub struct AIManager {
  pub cloud_service_wm: Arc<AICloudServiceMiddleware>,
  pub user_service: Arc<dyn AIUserService>,
  pub external_service: Arc<dyn AIExternalService>,
  chats: Arc<DashMap<String, Arc<Chat>>>,
  pub local_ai: Arc<LocalAIController>,
  pub store_preferences: Arc<KVStorePreferences>,
  server_models: Arc<RwLock<ServerModelsCache>>,
}

impl AIManager {
  pub fn new(
    chat_cloud_service: Arc<dyn ChatCloudService>,
    user_service: impl AIUserService,
    store_preferences: Arc<KVStorePreferences>,
    storage_service: Weak<dyn StorageService>,
    query_service: impl AIExternalService,
  ) -> AIManager {
    let user_service = Arc::new(user_service);
    let plugin_manager = Arc::new(PluginManager::new());
    let local_ai = Arc::new(LocalAIController::new(
      plugin_manager.clone(),
      store_preferences.clone(),
      user_service.clone(),
      chat_cloud_service.clone(),
    ));

    let cloned_local_ai = local_ai.clone();
    tokio::spawn(async move {
      cloned_local_ai.observe_plugin_resource().await;
    });

    let external_service = Arc::new(query_service);
    let cloud_service_wm = Arc::new(AICloudServiceMiddleware::new(
      user_service.clone(),
      chat_cloud_service,
      local_ai.clone(),
      storage_service,
    ));

    Self {
      cloud_service_wm,
      user_service,
      chats: Arc::new(DashMap::new()),
      local_ai,
      external_service,
      store_preferences,
      server_models: Arc::new(Default::default()),
    }
  }

  pub async fn initialize(&self, _workspace_id: &str) -> Result<(), FlowyError> {
    self.local_ai.reload().await?;
    Ok(())
  }

  pub async fn open_chat(&self, chat_id: &str) -> Result<(), FlowyError> {
    self.chats.entry(chat_id.to_string()).or_insert_with(|| {
      Arc::new(Chat::new(
        self.user_service.user_id().unwrap(),
        chat_id.to_string(),
        self.user_service.clone(),
        self.cloud_service_wm.clone(),
        self.store_preferences.clone(),
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
    let chat_id = chat_id.to_string();
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
          let _ = sync_chat_documents(user_service, external_service, settings.rag_ids).await;
        },
        Err(err) => {
          error!("failed to refresh chat settings: {}", err);
        },
      }
    });

    Ok(())
  }

  pub async fn close_chat(&self, chat_id: &str) -> Result<(), FlowyError> {
    trace!("close chat: {}", chat_id);
    self.local_ai.close_chat(chat_id);
    Ok(())
  }

  pub async fn delete_chat(&self, chat_id: &str) -> Result<(), FlowyError> {
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
    parent_view_id: &str,
    chat_id: &str,
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
      .create_chat(uid, &workspace_id, chat_id, rag_ids)
      .await?;
    save_chat(self.user_service.sqlite_connection(*uid)?, chat_id)?;

    let chat = Arc::new(Chat::new(
      self.user_service.user_id()?,
      chat_id.to_string(),
      self.user_service.clone(),
      self.cloud_service_wm.clone(),
      self.store_preferences.clone(),
    ));
    self.chats.insert(chat_id.to_string(), chat.clone());
    Ok(chat)
  }

  pub async fn stream_chat_message(
    &self,
    params: StreamMessageParams,
  ) -> Result<ChatMessagePB, FlowyError> {
    let chat = self.get_or_create_chat_instance(&params.chat_id).await?;
    let question = chat.stream_chat_message(&params).await?;
    let _ = self
      .external_service
      .notify_did_send_message(&params.chat_id, &params.message)
      .await;
    Ok(question)
  }

  pub async fn stream_regenerate_response(
    &self,
    chat_id: &str,
    answer_message_id: i64,
    answer_stream_port: i64,
    format: Option<PredefinedFormatPB>,
  ) -> FlowyResult<()> {
    let chat = self.get_or_create_chat_instance(chat_id).await?;
    let question_message_id = chat
      .get_question_id_from_answer_id(answer_message_id)
      .await?;

    let preferred_model = self
      .store_preferences
      .get_object::<AIModel>(&ai_available_models_key(chat_id));
    chat
      .stream_regenerate_response(
        question_message_id,
        answer_stream_port,
        format,
        preferred_model,
      )
      .await?;
    Ok(())
  }

  async fn get_workspace_select_model(&self) -> FlowyResult<String> {
    let workspace_id = self.user_service.workspace_id()?;
    let model = self
      .cloud_service_wm
      .get_workspace_default_model(&workspace_id)
      .await?;
    Ok(model)
  }

  async fn get_server_available_models(&self) -> FlowyResult<Vec<AvailableModel>> {
    let workspace_id = self.user_service.workspace_id()?;
    let now = timestamp();

    // First, try reading from the cache with expiration check
    let should_fetch = {
      let cached_models = self.server_models.read().await;
      cached_models.models.is_empty() || cached_models.timestamp.map_or(true, |ts| now - ts >= 300)
    };

    if !should_fetch {
      // Cache is still valid, return cached data
      let cached_models = self.server_models.read().await;
      return Ok(cached_models.models.clone());
    }

    // Cache miss or expired: fetch from the cloud.
    match self
      .cloud_service_wm
      .get_available_models(&workspace_id)
      .await
    {
      Ok(list) => {
        let models = list.models;
        if let Err(err) = self.update_models_cache(&models, now).await {
          error!("Failed to update models cache: {}", err);
        }

        Ok(models)
      },
      Err(err) => {
        error!("Failed to fetch available models: {}", err);

        // Return cached data if available, even if expired
        let cached_models = self.server_models.read().await;
        if !cached_models.models.is_empty() {
          info!("Returning expired cached models due to fetch failure");
          return Ok(cached_models.models.clone());
        }

        // If no cached data, return empty list
        Ok(Vec::new())
      },
    }
  }

  async fn update_models_cache(
    &self,
    models: &[AvailableModel],
    timestamp: i64,
  ) -> FlowyResult<()> {
    match self.server_models.try_write() {
      Ok(mut cache) => {
        cache.models = models.to_vec();
        cache.timestamp = Some(timestamp);
        Ok(())
      },
      Err(_) => {
        // Handle lock acquisition failure
        Err(FlowyError::internal().with_context("Failed to acquire write lock for models cache"))
      },
    }
  }

  pub async fn update_selected_model(&self, source: String, model: AIModel) -> FlowyResult<()> {
    let source_key = ai_available_models_key(&source);
    self
      .store_preferences
      .set_object::<AIModel>(&source_key, &model)?;

    chat_notification_builder(&source, ChatNotification::DidUpdateSelectedModel)
      .payload(AIModelPB::from(model))
      .send();
    Ok(())
  }

  #[instrument(skip_all, level = "debug")]
  pub async fn toggle_local_ai(&self) -> FlowyResult<()> {
    let enabled = self.local_ai.toggle_local_ai().await?;
    let source_key = ai_available_models_key(GLOBAL_ACTIVE_MODEL_KEY);
    if enabled {
      if let Some(name) = self.local_ai.get_plugin_chat_model() {
        info!("Set global active model to local ai: {}", name);
        let model = AIModel::local(name);
        self.update_selected_model(source_key, model).await?;
      }
    } else {
      info!("Set global active model to default");
      let global_active_model = self
        .get_workspace_select_model()
        .await
        .map(AIModel::server)
        .unwrap_or_else(|_| AIModel::default());

      self
        .update_selected_model(source_key, global_active_model)
        .await?;
    }

    Ok(())
  }

  pub async fn get_available_models(&self, source: String) -> FlowyResult<AvailableModelsPB> {
    // Build the models list from server models and mark them as non-local.
    let mut models: Vec<AIModelPB> = self
      .get_server_available_models()
      .await?
      .into_iter()
      .map(|m| AIModelPB::server(m.name))
      .collect();

    // If user enable local ai, then add local ai model to the list.
    if let Some(local_model) = self.local_ai.get_plugin_chat_model() {
      models.push(AIModelPB::local(local_model));
    }

    if models.is_empty() {
      return Ok(AvailableModelsPB {
        models,
        selected_model: AIModelPB::default(),
      });
    }

    // Global active model is the model selected by the user in the workspace settings.
    let global_active_model = self
      .get_workspace_select_model()
      .await
      .map(AIModel::server)
      .unwrap_or_else(|_| AIModel::default());

    let mut user_selected_model = global_active_model.clone();
    let source_key = ai_available_models_key(&source);

    // If source is provided, try to get the user-selected model from the store. User selected
    // model will be used as the active model if it exists.
    match self.store_preferences.get_object::<AIModel>(&source_key) {
      None => {
        // when there is selected model and current local ai is active, then use local ai
        if let Some(local_ai_model) = models.iter().find(|m| m.is_local) {
          user_selected_model = AIModel::from(local_ai_model.clone());
        }
      },
      Some(model) => {
        user_selected_model = model;
      },
    }

    // If user selected model is not available in the list, use the global active model.
    let active_model = models
      .iter()
      .find(|m| m.name == user_selected_model.name)
      .cloned()
      .or_else(|| Some(AIModelPB::from(global_active_model)));

    // Update the stored preference if a different model is used.
    if let Some(ref active_model) = active_model {
      if active_model.name != user_selected_model.name {
        self
          .store_preferences
          .set_object::<AIModel>(&source_key, &AIModel::from(active_model.clone()))?;
      }
    }

    Ok(AvailableModelsPB {
      models,
      selected_model: active_model.unwrap_or_default(),
    })
  }

  pub async fn get_or_create_chat_instance(&self, chat_id: &str) -> Result<Arc<Chat>, FlowyError> {
    let chat = self.chats.get(chat_id).as_deref().cloned();
    match chat {
      None => {
        let chat = Arc::new(Chat::new(
          self.user_service.user_id()?,
          chat_id.to_string(),
          self.user_service.clone(),
          self.cloud_service_wm.clone(),
          self.store_preferences.clone(),
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

  pub async fn get_rag_ids(&self, chat_id: &str) -> FlowyResult<Vec<String>> {
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

  pub async fn update_rag_ids(&self, chat_id: &str, rag_ids: Vec<String>) -> FlowyResult<()> {
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
    sync_chat_documents(user_service, external_service, rag_ids).await?;
    Ok(())
  }
}

async fn sync_chat_documents(
  user_service: Arc<dyn AIUserService>,
  external_service: Arc<dyn AIExternalService>,
  rag_ids: Vec<String>,
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

async fn refresh_chat_setting(
  user_service: &Arc<dyn AIUserService>,
  cloud_service: &Arc<AICloudServiceMiddleware>,
  store_preferences: &Arc<KVStorePreferences>,
  chat_id: &str,
) -> FlowyResult<ChatSettings> {
  info!("[Chat] refresh chat:{} setting", chat_id);
  let workspace_id = user_service.workspace_id()?;
  let settings = cloud_service
    .get_chat_settings(&workspace_id, chat_id)
    .await?;

  if let Err(err) = store_preferences.set_object(&setting_store_key(chat_id), &settings) {
    error!("failed to set chat settings: {}", err);
  }

  chat_notification_builder(chat_id, ChatNotification::DidUpdateChatSettings)
    .payload(ChatSettingsPB {
      rag_ids: settings.rag_ids.clone(),
    })
    .send();

  Ok(settings)
}

fn setting_store_key(chat_id: &str) -> String {
  format!("chat_settings_{}", chat_id)
}

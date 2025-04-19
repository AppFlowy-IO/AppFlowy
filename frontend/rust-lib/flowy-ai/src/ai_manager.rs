use crate::chat::Chat;
use crate::entities::{
  AIModelPB, AvailableModelsPB, ChatInfoPB, ChatMessageListPB, ChatMessagePB, ChatSettingsPB,
  FilePB, PredefinedFormatPB, RepeatedRelatedQuestionPB, StreamMessageParams,
};
use crate::local_ai::controller::{LocalAIController, LocalAISetting};
use crate::middleware::chat_service_mw::ChatServiceMiddleware;
use flowy_ai_pub::persistence::read_chat_metadata;
use std::collections::HashMap;

use dashmap::DashMap;
use flowy_ai_pub::cloud::{
  AIModel, ChatCloudService, ChatSettings, UpdateChatParams, DEFAULT_AI_MODEL_NAME,
};
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
use serde_json::json;
use std::path::PathBuf;
use std::str::FromStr;
use std::sync::{Arc, Weak};
use tokio::sync::RwLock;
use tracing::{error, info, instrument, trace};
use uuid::Uuid;

#[async_trait]
pub trait AIUserService: Send + Sync + 'static {
  fn user_id(&self) -> Result<i64, FlowyError>;
  async fn is_local_model(&self) -> FlowyResult<bool>;
  fn workspace_id(&self) -> Result<Uuid, FlowyError>;
  fn sqlite_connection(&self, uid: i64) -> Result<DBConnection, FlowyError>;
  fn application_root_dir(&self) -> Result<PathBuf, FlowyError>;
}

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

#[derive(Debug, Default)]
struct ServerModelsCache {
  models: Vec<AvailableModel>,
  timestamp: Option<i64>,
}

pub const GLOBAL_ACTIVE_MODEL_KEY: &str = "global_active_model";

pub struct AIManager {
  pub cloud_service_wm: Arc<ChatServiceMiddleware>,
  pub user_service: Arc<dyn AIUserService>,
  pub external_service: Arc<dyn AIExternalService>,
  chats: Arc<DashMap<Uuid, Arc<Chat>>>,
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

  #[instrument(skip_all, err)]
  pub async fn initialize(&self, _workspace_id: &str) -> Result<(), FlowyError> {
    let local_ai = self.local_ai.clone();
    tokio::spawn(async move {
      if let Err(err) = local_ai.destroy_plugin().await {
        error!("Failed to destroy plugin: {}", err);
      }

      if let Err(err) = local_ai.reload().await {
        error!("[AI Manager] failed to reload local AI: {:?}", err);
      }
    });
    Ok(())
  }

  #[instrument(skip_all, err)]
  pub async fn initialize_after_open_workspace(
    &self,
    _workspace_id: &str,
  ) -> Result<(), FlowyError> {
    let local_ai = self.local_ai.clone();
    tokio::spawn(async move {
      if let Err(err) = local_ai.destroy_plugin().await {
        error!("Failed to destroy plugin: {}", err);
      }

      if let Err(err) = local_ai.reload().await {
        error!("[AI Manager] failed to reload local AI: {:?}", err);
      }
    });
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
    let question = chat.stream_chat_message(&params, ai_model).await?;
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

    let model = model.map_or_else(
      || {
        self
          .store_preferences
          .get_object::<AIModel>(&ai_available_models_key(&chat_id.to_string()))
      },
      |model| Some(model.into()),
    );
    chat
      .stream_regenerate_response(question_message_id, answer_stream_port, format, model)
      .await?;
    Ok(())
  }

  pub async fn update_local_ai_setting(&self, setting: LocalAISetting) -> FlowyResult<()> {
    let previous_model = self.local_ai.get_local_ai_setting().chat_model_name;
    self.local_ai.update_local_ai_setting(setting).await?;
    let current_model = self.local_ai.get_local_ai_setting().chat_model_name;

    if previous_model != current_model {
      info!(
        "[AI Plugin] update global active model, previous: {}, current: {}",
        previous_model, current_model
      );
      let source_key = ai_available_models_key(GLOBAL_ACTIVE_MODEL_KEY);
      let model = AIModel::local(current_model, "".to_string());
      self.update_selected_model(source_key, model).await?;
    }

    Ok(())
  }

  async fn get_workspace_select_model(&self) -> FlowyResult<String> {
    let workspace_id = self.user_service.workspace_id()?;
    let model = self
      .cloud_service_wm
      .get_workspace_default_model(&workspace_id)
      .await?;

    if model.is_empty() {
      return Ok(DEFAULT_AI_MODEL_NAME.to_string());
    }
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
    info!(
      "[Model Selection] update {} selected model: {:?}",
      source, model
    );
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
        let model = AIModel::local(name, "".to_string());
        self.update_selected_model(source_key, model).await?;
      }
    } else {
      info!("Set global active model to default");
      let global_active_model = self.get_workspace_select_model().await?;
      let models = self.get_server_available_models().await?;
      if let Some(model) = models.into_iter().find(|m| m.name == global_active_model) {
        self
          .update_selected_model(source_key, AIModel::from(model))
          .await?;
      }
    }

    Ok(())
  }

  pub async fn get_active_model(&self, source: &str) -> Option<AIModel> {
    let mut model = self
      .store_preferences
      .get_object::<AIModel>(&ai_available_models_key(source));

    if model.is_none() {
      if let Some(local_model) = self.local_ai.get_plugin_chat_model() {
        model = Some(AIModel::local(local_model, "".to_string()));
      }
    }

    model
  }

  pub async fn get_available_models(&self, source: String) -> FlowyResult<AvailableModelsPB> {
    let is_local_mode = self.user_service.is_local_model().await?;
    if is_local_mode {
      let mut selected_model = AIModel::default();
      let mut models = vec![];
      if let Some(local_model) = self.local_ai.get_plugin_chat_model() {
        let model = AIModel::local(local_model, "".to_string());
        selected_model = model.clone();
        models.push(model);
      }

      Ok(AvailableModelsPB {
        models: models.into_iter().map(|m| m.into()).collect(),
        selected_model: AIModelPB::from(selected_model),
      })
    } else {
      // Build the models list from server models and mark them as non-local.
      let mut models: Vec<AIModel> = self
        .get_server_available_models()
        .await?
        .into_iter()
        .map(AIModel::from)
        .collect();

      trace!("[Model Selection]: Available models: {:?}", models);
      let mut current_active_local_ai_model = None;

      // If user enable local ai, then add local ai model to the list.
      if let Some(local_model) = self.local_ai.get_plugin_chat_model() {
        let model = AIModel::local(local_model, "".to_string());
        current_active_local_ai_model = Some(model.clone());
        trace!("[Model Selection] current local ai model: {}", model.name);
        models.push(model);
      }

      if models.is_empty() {
        return Ok(AvailableModelsPB {
          models: models.into_iter().map(|m| m.into()).collect(),
          selected_model: AIModelPB::default(),
        });
      }

      // Global active model is the model selected by the user in the workspace settings.
      let mut server_active_model = self
        .get_workspace_select_model()
        .await
        .map(|m| AIModel::server(m, "".to_string()))
        .unwrap_or_else(|_| AIModel::default());

      trace!(
        "[Model Selection] server active model: {:?}",
        server_active_model
      );

      let mut user_selected_model = server_active_model.clone();
      // when current select model is deprecated, reset the model to default
      if !models.iter().any(|m| m.name == server_active_model.name) {
        server_active_model = AIModel::default();
      }

      let source_key = ai_available_models_key(&source);
      // We use source to identify user selected model. source can be document id or chat id.
      match self.store_preferences.get_object::<AIModel>(&source_key) {
        None => {
          // when there is selected model and current local ai is active, then use local ai
          if let Some(local_ai_model) = models.iter().find(|m| m.is_local) {
            user_selected_model = local_ai_model.clone();
          }
        },
        Some(mut model) => {
          trace!("[Model Selection] user previous select model: {:?}", model);
          // If source is provided, try to get the user-selected model from the store. User selected
          // model will be used as the active model if it exists.
          if model.is_local {
            if let Some(local_ai_model) = &current_active_local_ai_model {
              if local_ai_model.name != model.name {
                model = local_ai_model.clone();
              }
            }
          }

          user_selected_model = model;
        },
      }

      // If user selected model is not available in the list, use the global active model.
      let active_model = models
        .iter()
        .find(|m| m.name == user_selected_model.name)
        .cloned()
        .or(Some(server_active_model.clone()));

      // Update the stored preference if a different model is used.
      if let Some(ref active_model) = active_model {
        if active_model.name != user_selected_model.name {
          self
            .store_preferences
            .set_object::<AIModel>(&source_key, &active_model.clone())?;
        }
      }

      trace!("[Model Selection] final active model: {:?}", active_model);
      let selected_model = AIModelPB::from(active_model.unwrap_or_default());
      Ok(AvailableModelsPB {
        models: models.into_iter().map(|m| m.into()).collect(),
        selected_model,
      })
    }
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
    let resp = chat.get_related_question(message_id, ai_model).await?;
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

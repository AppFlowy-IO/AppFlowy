use crate::local_ai::controller::LocalAIController;
use arc_swap::ArcSwapOption;
use flowy_ai_pub::cloud::{AIModel, ChatCloudService};
use flowy_error::{FlowyError, FlowyResult};
use flowy_sqlite::kv::KVStorePreferences;
use lib_infra::async_trait::async_trait;
use lib_infra::util::timestamp;
use std::sync::Arc;
use tokio::sync::RwLock;
use tracing::{error, info, trace};
use uuid::Uuid;

type Model = AIModel;
pub const GLOBAL_ACTIVE_MODEL_KEY: &str = "global_active_model";

/// Manages multiple sources and provides operations for model selection
pub struct ModelSelectionControl {
  sources: Vec<Box<dyn ModelSource>>,
  default_model: Model,
  local_storage: ArcSwapOption<Box<dyn UserModelStorage>>,
  server_storage: ArcSwapOption<Box<dyn UserModelStorage>>,
}

impl ModelSelectionControl {
  /// Create a new manager with the given storage backends
  pub fn new() -> Self {
    let default_model = Model::default();
    Self {
      sources: Vec::new(),
      default_model,
      local_storage: ArcSwapOption::new(None),
      server_storage: ArcSwapOption::new(None),
    }
  }

  /// Replace the local storage backend at runtime
  pub fn set_local_storage(&self, storage: impl UserModelStorage + 'static) {
    self.local_storage.store(Some(Arc::new(Box::new(storage))));
  }

  /// Replace the server storage backend at runtime
  pub fn set_server_storage(&self, storage: impl UserModelStorage + 'static) {
    self.server_storage.store(Some(Arc::new(Box::new(storage))));
  }

  /// Add a new model source at runtime
  pub fn add_source(&mut self, source: Box<dyn ModelSource>) {
    info!("[Model Selection] Adding source: {}", source.source_name());
    self.sources.push(source);
  }

  /// Remove all sources matching the given name
  pub fn remove_local_source(&mut self) {
    info!("[Model Selection] Removing local source");
    self
      .sources
      .retain(|source| source.source_name() != "local");
  }

  /// Asynchronously aggregate models from all sources, or return the default if none found
  pub async fn get_models(&self, workspace_id: &Uuid) -> Vec<Model> {
    let mut models = Vec::new();
    for source in &self.sources {
      let mut list = source.list_chat_models(workspace_id).await;
      models.append(&mut list);
    }
    if models.is_empty() {
      vec![self.default_model.clone()]
    } else {
      models
    }
  }

  /// Fetches all server‐side models and, if specified, a single local model by name.
  ///
  /// First collects models from any source named `"server"`. Then it fetches all local models
  /// (from the `"local"` source) and:
  /// - If `local_model_name` is `Some(name)`, it will append exactly that local model
  ///   if it exists.
  /// - If `local_model_name` is `None`, it will append *all* local models.
  ///
  pub async fn get_models_with_specific_local_model(
    &self,
    workspace_id: &Uuid,
    local_model_name: Option<String>,
  ) -> Vec<Model> {
    let mut models = Vec::new();
    // add server models
    for source in &self.sources {
      if source.source_name() == "server" {
        let mut list = source.list_chat_models(workspace_id).await;
        models.append(&mut list);
      }
    }

    // check input local  model present in local models
    let local_models = self.get_local_models(workspace_id).await;
    match local_model_name {
      Some(name) => {
        local_models.into_iter().for_each(|model| {
          if model.name == name {
            models.push(model);
          }
        });
      },
      None => {
        models.extend(local_models);
      },
    }

    models
  }

  pub async fn get_local_models(&self, workspace_id: &Uuid) -> Vec<Model> {
    for source in &self.sources {
      if source.source_name() == "local" {
        return source.list_chat_models(workspace_id).await;
      }
    }
    vec![]
  }

  /// Retrieves the active model: first tries local storage, then server storage. Ensures validity in the model list.
  /// If neither storage yields a valid model, falls back to default.
  pub async fn get_active_model(&self, workspace_id: &Uuid, source_key: &SourceKey) -> Model {
    let available = self.get_models(workspace_id).await;
    // Try local storage
    if let Some(storage) = self.local_storage.load_full() {
      trace!("[Model Selection] Checking local storage");
      if let Some(local_model) = storage.get_selected_model(workspace_id, source_key).await {
        trace!("[Model Selection] Found local model: {}", local_model.name);
        if available.contains(&local_model) {
          info!("[Model Selection] Found local model: {}", local_model.name);
          return local_model;
        }
      }
    }

    // use local model if user doesn't set the model for given source
    if self
      .sources
      .iter()
      .any(|source| source.source_name() == "local")
    {
      trace!("[Model Selection] Checking global active model");
      let global_source = SourceKey::new(GLOBAL_ACTIVE_MODEL_KEY.to_string());
      if let Some(storage) = self.local_storage.load_full() {
        if let Some(local_model) = storage
          .get_selected_model(workspace_id, &global_source)
          .await
        {
          trace!(
            "[Model Selection] Found global active model: {}",
            local_model.name
          );
          if available.contains(&local_model) {
            return local_model;
          }
        }
      }
    }

    // Try server storage
    if let Some(storage) = self.server_storage.load_full() {
      trace!("[Model Selection] Checking server storage");
      if let Some(server_model) = storage.get_selected_model(workspace_id, source_key).await {
        trace!(
          "[Model Selection] Found server model: {}",
          server_model.name
        );
        if available.contains(&server_model) {
          info!(
            "[Model Selection] Found server model: {}",
            server_model.name
          );
          return server_model;
        }
      }
    }
    // Fallback: default
    info!(
      "[Model Selection] No active model found, using default: {}",
      self.default_model.name
    );
    self.default_model.clone()
  }

  /// Sets the active model in both local and server storage
  pub async fn set_active_model(
    &self,
    workspace_id: &Uuid,
    source_key: &SourceKey,
    model: Model,
  ) -> Result<(), FlowyError> {
    let available = self.get_models(workspace_id).await;
    if available.contains(&model) {
      // Update local storage
      if let Some(storage) = self.local_storage.load_full() {
        storage
          .set_selected_model(workspace_id, source_key, model.clone())
          .await?;
      }

      // Update server storage
      if let Some(storage) = self.server_storage.load_full() {
        storage
          .set_selected_model(workspace_id, source_key, model)
          .await?;
      }
      Ok(())
    } else {
      Err(
        FlowyError::internal()
          .with_context(format!("Model '{:?}' not found in available list", model)),
      )
    }
  }
}

/// Namespaced key for model selection storage
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct SourceKey {
  key: String,
}

impl SourceKey {
  /// Create a new SourceKey
  pub fn new(key: String) -> Self {
    Self { key }
  }

  /// Combine the UUID key with a model's is_local flag and name to produce a storage identifier
  pub fn storage_id(&self) -> String {
    format!("ai_models_{}", self.key)
  }
}

/// A trait that defines an asynchronous source of AI models
#[async_trait]
pub trait ModelSource: Send + Sync {
  /// Identifier for this source (e.g., "local" or "server")
  fn source_name(&self) -> &'static str;

  /// Asynchronously returns a list of available models from this source
  async fn list_chat_models(&self, workspace_id: &Uuid) -> Vec<Model>;
}

pub struct LocalAiSource {
  controller: Arc<LocalAIController>,
}

impl LocalAiSource {
  pub fn new(controller: Arc<LocalAIController>) -> Self {
    Self { controller }
  }
}

#[async_trait]
impl ModelSource for LocalAiSource {
  fn source_name(&self) -> &'static str {
    "local"
  }

  async fn list_chat_models(&self, _workspace_id: &Uuid) -> Vec<Model> {
    match self.controller.ollama.load_full() {
      None => vec![],
      Some(ollama) => ollama
        .list_local_models()
        .await
        .map(|models| {
          models
            .into_iter()
            .filter(|m| !m.name.contains("embed"))
            .map(|m| AIModel::local(m.name, String::new()))
            .collect()
        })
        .unwrap_or_default(),
    }
  }
}

/// A server-side AI source (e.g., cloud API)
#[derive(Debug, Default)]
struct ServerModelsCache {
  models: Vec<Model>,
  timestamp: Option<i64>,
}

pub struct ServerAiSource {
  cached_models: Arc<RwLock<ServerModelsCache>>,
  cloud_service: Arc<dyn ChatCloudService>,
}

impl ServerAiSource {
  pub fn new(cloud_service: Arc<dyn ChatCloudService>) -> Self {
    Self {
      cached_models: Arc::new(Default::default()),
      cloud_service,
    }
  }

  async fn update_models_cache(&self, models: &[Model], timestamp: i64) -> FlowyResult<()> {
    match self.cached_models.try_write() {
      Ok(mut cache) => {
        cache.models = models.to_vec();
        cache.timestamp = Some(timestamp);
        Ok(())
      },
      Err(_) => {
        Err(FlowyError::internal().with_context("Failed to acquire write lock for models cache"))
      },
    }
  }
}

#[async_trait]
impl ModelSource for ServerAiSource {
  fn source_name(&self) -> &'static str {
    "server"
  }

  async fn list_chat_models(&self, workspace_id: &Uuid) -> Vec<Model> {
    let now = timestamp();
    let should_fetch = {
      let cached = self.cached_models.read().await;
      cached.models.is_empty() || cached.timestamp.map_or(true, |ts| now - ts >= 300)
    };
    if !should_fetch {
      return self.cached_models.read().await.models.clone();
    }
    match self.cloud_service.get_available_models(workspace_id).await {
      Ok(resp) => {
        let models = resp
          .models
          .into_iter()
          .map(AIModel::from)
          .collect::<Vec<_>>();
        if let Err(e) = self.update_models_cache(&models, now).await {
          error!("Failed to update cache: {}", e);
        }
        models
      },
      Err(err) => {
        error!("Failed to fetch models: {}", err);
        let cached = self.cached_models.read().await;
        if !cached.models.is_empty() {
          info!("Returning expired cache due to error");
          return cached.models.clone();
        }
        Vec::new()
      },
    }
  }
}

#[async_trait]
pub trait UserModelStorage: Send + Sync {
  async fn get_selected_model(&self, workspace_id: &Uuid, source_key: &SourceKey) -> Option<Model>;
  async fn set_selected_model(
    &self,
    workspace_id: &Uuid,
    source_key: &SourceKey,
    model: Model,
  ) -> Result<(), FlowyError>;
}

pub struct ServerModelStorageImpl(pub Arc<dyn ChatCloudService>);

#[async_trait]
impl UserModelStorage for ServerModelStorageImpl {
  async fn get_selected_model(
    &self,
    workspace_id: &Uuid,
    _source_key: &SourceKey,
  ) -> Option<Model> {
    let name = self
      .0
      .get_workspace_default_model(workspace_id)
      .await
      .ok()?;
    Some(Model::server(name, String::new()))
  }

  async fn set_selected_model(
    &self,
    workspace_id: &Uuid,
    _source_key: &SourceKey,
    model: Model,
  ) -> Result<(), FlowyError> {
    if model.is_local {
      // local model does not need to be set
      return Ok(());
    }

    self
      .0
      .set_workspace_default_model(workspace_id, &model.name)
      .await?;
    Ok(())
  }
}

pub struct LocalModelStorageImpl(pub Arc<KVStorePreferences>);

#[async_trait]
impl UserModelStorage for LocalModelStorageImpl {
  async fn get_selected_model(
    &self,
    _workspace_id: &Uuid,
    source_key: &SourceKey,
  ) -> Option<Model> {
    self.0.get_object::<AIModel>(&source_key.storage_id())
  }

  async fn set_selected_model(
    &self,
    _workspace_id: &Uuid,
    source_key: &SourceKey,
    model: Model,
  ) -> Result<(), FlowyError> {
    self
      .0
      .set_object::<AIModel>(&source_key.storage_id(), &model)?;
    Ok(())
  }
}

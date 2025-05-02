use crate::entities::{LocalAIPB, RunningStatePB};
use crate::local_ai::resource::{LLMResourceService, LocalAIResourceController};
use crate::notification::{
  chat_notification_builder, ChatNotification, APPFLOWY_AI_NOTIFICATION_KEY,
};
use af_plugin::manager::PluginManager;
use anyhow::Error;
use flowy_error::{FlowyError, FlowyResult};
use flowy_sqlite::kv::KVStorePreferences;
use futures::Sink;
use lib_infra::async_trait::async_trait;
use std::collections::HashMap;

use crate::stream_message::StreamMessage;
use af_local_ai::ollama_plugin::OllamaAIPlugin;
use af_plugin::core::path::is_plugin_ready;
use af_plugin::core::plugin::RunningState;
use arc_swap::ArcSwapOption;
use flowy_ai_pub::cloud::AIModel;
use flowy_ai_pub::persistence::{
  select_local_ai_model, upsert_local_ai_model, LocalAIModelTable, ModelType,
};
use flowy_ai_pub::user_service::AIUserService;
use futures_util::SinkExt;
use lib_infra::util::get_operating_system;
use ollama_rs::generation::embeddings::request::{EmbeddingsInput, GenerateEmbeddingsRequest};
use ollama_rs::Ollama;
use serde::{Deserialize, Serialize};
use std::ops::Deref;
use std::path::PathBuf;
use std::sync::{Arc, Weak};
use tokio::select;
use tokio_stream::StreamExt;
use tracing::{debug, error, info, instrument, warn};
use uuid::Uuid;

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct LocalAISetting {
  pub ollama_server_url: String,
  pub chat_model_name: String,
  pub embedding_model_name: String,
}

impl Default for LocalAISetting {
  fn default() -> Self {
    Self {
      ollama_server_url: "http://localhost:11434".to_string(),
      chat_model_name: "llama3.1:latest".to_string(),
      embedding_model_name: "nomic-embed-text:latest".to_string(),
    }
  }
}

const LOCAL_AI_SETTING_KEY: &str = "appflowy_local_ai_setting:v1";

pub struct LocalAIController {
  ai_plugin: Arc<OllamaAIPlugin>,
  resource: Arc<LocalAIResourceController>,
  current_chat_id: ArcSwapOption<Uuid>,
  store_preferences: Weak<KVStorePreferences>,
  user_service: Arc<dyn AIUserService>,
  pub(crate) ollama: ArcSwapOption<Ollama>,
}

impl Deref for LocalAIController {
  type Target = Arc<OllamaAIPlugin>;

  fn deref(&self) -> &Self::Target {
    &self.ai_plugin
  }
}

impl LocalAIController {
  pub fn new(
    plugin_manager: Arc<PluginManager>,
    store_preferences: Weak<KVStorePreferences>,
    user_service: Arc<dyn AIUserService>,
  ) -> Self {
    debug!(
      "[Local AI] init local ai controller, thread: {:?}",
      std::thread::current().id()
    );

    // Create the core plugin and resource controller
    let local_ai = Arc::new(OllamaAIPlugin::new(plugin_manager));
    let res_impl = LLMResourceServiceImpl {
      store_preferences: store_preferences.clone(),
    };
    let local_ai_resource = Arc::new(LocalAIResourceController::new(
      user_service.clone(),
      res_impl,
    ));

    let ollama = ArcSwapOption::default();

    let sys = get_operating_system();
    if sys.is_desktop() {
      // Subscribe to state changes
      let mut running_state_rx = local_ai.subscribe_running_state();
      let cloned_llm_res = Arc::clone(&local_ai_resource);
      let cloned_store_preferences = store_preferences.clone();
      let cloned_local_ai = Arc::clone(&local_ai);
      let cloned_user_service = Arc::clone(&user_service);

      // Spawn a background task to listen for plugin state changes
      tokio::spawn(async move {
        while let Some(state) = running_state_rx.next().await {
          // Skip if we can't get workspace_id
          let Ok(workspace_id) = cloned_user_service.workspace_id() else {
            continue;
          };

          let key = local_ai_enabled_key(&workspace_id.to_string());
          info!("[Local AI] state: {:?}", state);

          // Read whether plugin is enabled from store; default to true
          if let Some(store_preferences) = cloned_store_preferences.upgrade() {
            let enabled = store_preferences.get_bool(&key).unwrap_or(true);
            // Only check resource status if the plugin isn't in "UnexpectedStop" and is enabled
            let (plugin_downloaded, lack_of_resource) =
              if !matches!(state, RunningState::UnexpectedStop { .. }) && enabled {
                // Possibly check plugin readiness and resource concurrency in parallel,
                // but here we do it sequentially for clarity.
                let downloaded = is_plugin_ready();
                let resource_lack = cloned_llm_res.get_lack_of_resource().await;
                (downloaded, resource_lack)
              } else {
                (false, None)
              };

            // If plugin is running, retrieve version
            let plugin_version = if matches!(state, RunningState::Running { .. }) {
              match cloned_local_ai.plugin_info().await {
                Ok(info) => Some(info.version),
                Err(_) => None,
              }
            } else {
              None
            };

            // Broadcast the new local AI state
            let new_state = RunningStatePB::from(state);
            chat_notification_builder(
              APPFLOWY_AI_NOTIFICATION_KEY,
              ChatNotification::UpdateLocalAIState,
            )
            .payload(LocalAIPB {
              enabled,
              plugin_downloaded,
              lack_of_resource,
              state: new_state,
              plugin_version,
            })
            .send();
          } else {
            warn!("[Local AI] store preferences is dropped");
          }
        }
      });
    }

    Self {
      ai_plugin: local_ai,
      resource: local_ai_resource,
      current_chat_id: ArcSwapOption::default(),
      store_preferences,
      user_service,
      ollama,
    }
  }

  pub fn reload_ollama_client(&self, workspace_id: &str) {
    if !self.is_enabled_on_workspace(workspace_id) {
      return;
    }

    let setting = self.resource.get_llm_setting();
    if let Some(ollama) = self.ollama.load_full() {
      if ollama.url_str() == setting.ollama_server_url {
        info!("[Local AI] ollama client is already initialized");
        return;
      }
    }

    info!("[Local AI] reloading ollama client");
    match Ollama::try_new(setting.ollama_server_url).map(Arc::new) {
      Ok(new_ollama) => {
        self.ollama.store(Some(new_ollama.clone()));

        #[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
        crate::embeddings::context::EmbedContext::shared().set_ollama(Some(new_ollama.clone()));
      },
      Err(err) => error!(
        "failed to create ollama client: {:?}, thread: {:?}",
        err,
        std::thread::current().id()
      ),
    }
  }

  #[instrument(level = "debug", skip_all)]
  pub async fn observe_plugin_resource(&self) {
    let sys = get_operating_system();
    if !sys.is_desktop() {
      return;
    }

    debug!(
      "[Local AI] observer plugin state. thread: {:?}",
      std::thread::current().id()
    );
    async fn try_init_plugin(
      resource: &Arc<LocalAIResourceController>,
      ai_plugin: &Arc<OllamaAIPlugin>,
    ) {
      if let Err(err) = initialize_ai_plugin(ai_plugin, resource, None).await {
        error!("[Local AI] failed to setup plugin: {:?}", err);
      }
    }

    // Clone what is needed for the background task.
    let resource_clone = self.resource.clone();
    let ai_plugin_clone = self.ai_plugin.clone();
    let mut resource_notify = self.resource.subscribe_resource_notify();
    let mut app_state_watcher = self.resource.subscribe_app_state();
    tokio::spawn(async move {
      loop {
        select! {
            _ = app_state_watcher.recv() => {
                info!("[Local AI] app state changed, try to init plugin");
                try_init_plugin(&resource_clone, &ai_plugin_clone).await;
            },
            _ = resource_notify.recv() => {
                info!("[Local AI] resource changed, try to init plugin");
                try_init_plugin(&resource_clone, &ai_plugin_clone).await;
            },
            else => break,
        }
      }
    });
  }

  fn upgrade_store_preferences(&self) -> FlowyResult<Arc<KVStorePreferences>> {
    self
      .store_preferences
      .upgrade()
      .ok_or_else(|| FlowyError::internal().with_context("Store preferences is dropped"))
  }

  /// Indicate whether the local AI plugin is running.
  pub fn is_running(&self) -> bool {
    self.ai_plugin.get_plugin_running_state().is_running()
  }

  /// Indicate whether the local AI is enabled.
  /// AppFlowy store the value in local storage isolated by workspace id. Each workspace can have
  /// different settings.
  pub fn is_enabled(&self) -> bool {
    if !get_operating_system().is_desktop() {
      return false;
    }

    if let Ok(workspace_id) = self.user_service.workspace_id() {
      self.is_enabled_on_workspace(&workspace_id.to_string())
    } else {
      false
    }
  }

  pub fn is_enabled_on_workspace(&self, workspace_id: &str) -> bool {
    let key = local_ai_enabled_key(workspace_id);
    if !get_operating_system().is_desktop() {
      return false;
    }

    match self.upgrade_store_preferences() {
      Ok(store) => store.get_bool(&key).unwrap_or(false),
      Err(_) => false,
    }
  }

  pub fn get_plugin_chat_model(&self) -> Option<String> {
    if !self.is_enabled() {
      return None;
    }
    Some(self.resource.get_llm_setting().chat_model_name)
  }

  pub fn open_chat(&self, chat_id: &Uuid) {
    if !self.is_enabled() {
      return;
    }

    // Only keep one chat open at a time. Since loading multiple models at the same time will cause
    // memory issues.
    if let Some(current_chat_id) = self.current_chat_id.load().as_ref() {
      debug!("[Local AI] close previous chat: {}", current_chat_id);
      self.close_chat(current_chat_id);
    }

    self.current_chat_id.store(Some(Arc::new(*chat_id)));
    let chat_id = chat_id.to_string();
    let weak_ctrl = Arc::downgrade(&self.ai_plugin);
    tokio::spawn(async move {
      if let Some(ctrl) = weak_ctrl.upgrade() {
        if let Err(err) = ctrl.create_chat(&chat_id).await {
          error!("[Local AI] failed to open chat: {:?}", err);
        }
      }
    });
  }

  pub fn close_chat(&self, chat_id: &Uuid) {
    if !self.is_running() {
      return;
    }
    info!("[Local AI] notify close chat: {}", chat_id);
    let weak_ctrl = Arc::downgrade(&self.ai_plugin);
    let chat_id = chat_id.to_string();
    tokio::spawn(async move {
      if let Some(ctrl) = weak_ctrl.upgrade() {
        if let Err(err) = ctrl.close_chat(&chat_id).await {
          error!("[Local AI] failed to close chat: {:?}", err);
        }
      }
    });
  }

  pub fn get_local_ai_setting(&self) -> LocalAISetting {
    self.resource.get_llm_setting()
  }

  pub async fn get_all_chat_local_models(&self) -> Vec<AIModel> {
    self
      .get_filtered_local_models(|name| !name.contains("embed"))
      .await
  }

  pub async fn get_all_embedded_local_models(&self) -> Vec<AIModel> {
    self
      .get_filtered_local_models(|name| name.contains("embed"))
      .await
  }

  // Helper function to avoid code duplication in model retrieval
  async fn get_filtered_local_models<F>(&self, filter_fn: F) -> Vec<AIModel>
  where
    F: Fn(&str) -> bool,
  {
    match self.ollama.load_full() {
      None => vec![],
      Some(ollama) => ollama
        .list_local_models()
        .await
        .map(|models| {
          models
            .into_iter()
            .filter(|m| filter_fn(&m.name.to_lowercase()))
            .map(|m| AIModel::local(m.name, String::new()))
            .collect()
        })
        .unwrap_or_default(),
    }
  }

  pub async fn check_model_type(&self, model_name: &str) -> FlowyResult<ModelType> {
    let uid = self.user_service.user_id()?;
    let mut conn = self.user_service.sqlite_connection(uid)?;
    match select_local_ai_model(&mut conn, model_name) {
      None => {
        let ollama = self
          .ollama
          .load_full()
          .ok_or_else(|| FlowyError::local_ai().with_context("ollama is not initialized"))?;

        let request = GenerateEmbeddingsRequest::new(
          model_name.to_string(),
          EmbeddingsInput::Single("Hello".to_string()),
        );

        let model_type = match ollama.generate_embeddings(request).await {
          Ok(value) => {
            if value.embeddings.is_empty() {
              ModelType::Chat
            } else {
              ModelType::Embedding
            }
          },
          Err(_) => ModelType::Chat,
        };

        upsert_local_ai_model(
          &mut conn,
          &LocalAIModelTable {
            name: model_name.to_string(),
            model_type: model_type as i16,
          },
        )?;
        Ok(model_type)
      },
      Some(r) => Ok(ModelType::from(r.model_type)),
    }
  }

  pub async fn update_local_ai_setting(&self, setting: LocalAISetting) -> FlowyResult<()> {
    info!(
      "[Local AI] update local ai setting: {:?}, thread: {:?}",
      setting,
      std::thread::current().id()
    );
    self.resource.set_llm_setting(setting).await?;
    Ok(())
  }

  #[instrument(level = "debug", skip_all)]
  pub async fn get_local_ai_state(&self) -> LocalAIPB {
    let start = std::time::Instant::now();
    let enabled = self.is_enabled();

    // If not enabled, return immediately.
    if !enabled {
      debug!(
        "[Local AI] get local ai state, elapsed: {:?}, thread: {:?}",
        start.elapsed(),
        std::thread::current().id()
      );
      return LocalAIPB {
        enabled,
        plugin_downloaded: false,
        state: RunningStatePB::from(RunningState::ReadyToConnect),
        lack_of_resource: None,
        plugin_version: None,
      };
    }

    let plugin_downloaded = is_plugin_ready();
    let state = self.ai_plugin.get_plugin_running_state();

    // If the plugin is running, run both requests in parallel.
    // Otherwise, only fetch the resource info.
    let (plugin_version, lack_of_resource) = if matches!(state, RunningState::Running { .. }) {
      // Launch both futures at once
      let plugin_info_fut = self.ai_plugin.plugin_info();
      let resource_fut = self.resource.get_lack_of_resource();

      let (plugin_info_res, resource_res) = tokio::join!(plugin_info_fut, resource_fut);
      let plugin_version = plugin_info_res.ok().map(|info| info.version);
      (plugin_version, resource_res)
    } else {
      let resource_res = self.resource.get_lack_of_resource().await;
      (None, resource_res)
    };

    let elapsed = start.elapsed();
    debug!(
      "[Local AI] get local ai state, elapsed: {:?}, thread: {:?}",
      elapsed,
      std::thread::current().id()
    );

    LocalAIPB {
      enabled,
      plugin_downloaded,
      state: RunningStatePB::from(state),
      lack_of_resource,
      plugin_version,
    }
  }
  #[instrument(level = "debug", skip_all)]
  pub async fn restart_plugin(&self) {
    if let Err(err) = initialize_ai_plugin(&self.ai_plugin, &self.resource, None).await {
      error!("[Local AI] failed to setup plugin: {:?}", err);
    }
  }

  pub fn get_model_storage_directory(&self) -> FlowyResult<String> {
    self
      .resource
      .user_model_folder()
      .map(|path| path.to_string_lossy().to_string())
  }

  pub async fn toggle_local_ai(&self) -> FlowyResult<bool> {
    let workspace_id = self.user_service.workspace_id()?;
    let key = local_ai_enabled_key(&workspace_id.to_string());
    let store_preferences = self.upgrade_store_preferences()?;
    let enabled = !store_preferences.get_bool(&key).unwrap_or(false);
    tracing::trace!("[Local AI] toggle local ai, enabled: {}", enabled,);
    store_preferences.set_bool(&key, enabled)?;
    self.toggle_plugin(enabled).await?;
    Ok(enabled)
  }

  // #[instrument(level = "debug", skip_all)]
  // pub async fn index_message_metadata(
  //   &self,
  //   chat_id: &Uuid,
  //   metadata_list: &[ChatMessageMetadata],
  //   index_process_sink: &mut (impl Sink<String> + Unpin),
  // ) -> FlowyResult<()> {
  //   if !self.is_enabled() {
  //     info!("[Local AI] local ai is disabled, skip indexing");
  //     return Ok(());
  //   }
  //
  //   for metadata in metadata_list {
  //     let mut file_metadata = HashMap::new();
  //     file_metadata.insert("id".to_string(), json!(&metadata.id));
  //     file_metadata.insert("name".to_string(), json!(&metadata.name));
  //     file_metadata.insert("source".to_string(), json!(&metadata.source));
  //
  //     let file_path = Path::new(&metadata.data.content);
  //     if !file_path.exists() {
  //       return Err(
  //         FlowyError::record_not_found().with_context(format!("File not found: {:?}", file_path)),
  //       );
  //     }
  //     info!(
  //       "[Local AI] embed file: {:?}, with metadata: {:?}",
  //       file_path, file_metadata
  //     );
  //
  //     match &metadata.data.content_type {
  //       ContextLoader::Unknown => {
  //         error!(
  //           "[Local AI] unsupported content type: {:?}",
  //           metadata.data.content_type
  //         );
  //       },
  //       ContextLoader::Text | ContextLoader::Markdown | ContextLoader::PDF => {
  //         self
  //           .process_index_file(
  //             chat_id,
  //             file_path.to_path_buf(),
  //             &file_metadata,
  //             index_process_sink,
  //           )
  //           .await?;
  //       },
  //     }
  //   }
  //
  //   Ok(())
  // }

  #[allow(dead_code)]
  async fn process_index_file(
    &self,
    chat_id: &Uuid,
    file_path: PathBuf,
    index_metadata: &HashMap<String, serde_json::Value>,
    index_process_sink: &mut (impl Sink<String> + Unpin),
  ) -> Result<(), FlowyError> {
    let file_name = file_path
      .file_name()
      .unwrap_or_default()
      .to_string_lossy()
      .to_string();

    let _ = index_process_sink
      .send(
        StreamMessage::StartIndexFile {
          file_name: file_name.clone(),
        }
        .to_string(),
      )
      .await;

    let result = self
      .ai_plugin
      .embed_file(
        &chat_id.to_string(),
        file_path,
        Some(index_metadata.clone()),
      )
      .await;
    match result {
      Ok(_) => {
        let _ = index_process_sink
          .send(StreamMessage::EndIndexFile { file_name }.to_string())
          .await;
      },
      Err(err) => {
        let _ = index_process_sink
          .send(StreamMessage::IndexFileError { file_name }.to_string())
          .await;
        error!("[Local AI] failed to index file: {:?}", err);
      },
    }

    Ok(())
  }

  #[instrument(level = "debug", skip_all)]
  pub(crate) async fn toggle_plugin(&self, enabled: bool) -> FlowyResult<()> {
    info!(
      "[Local AI] enable: {}, thread id: {:?}",
      enabled,
      std::thread::current().id()
    );
    if enabled {
      let (tx, rx) = tokio::sync::oneshot::channel();
      if let Err(err) = initialize_ai_plugin(&self.ai_plugin, &self.resource, Some(tx)).await {
        error!("[Local AI] failed to initialize local ai: {:?}", err);
      }
      let _ = rx.await;
    } else {
      if let Err(err) = self.ai_plugin.destroy_plugin().await {
        error!("[Local AI] failed to destroy plugin: {:?}", err);
      }

      chat_notification_builder(
        APPFLOWY_AI_NOTIFICATION_KEY,
        ChatNotification::UpdateLocalAIState,
      )
      .payload(LocalAIPB {
        enabled,
        plugin_downloaded: true,
        state: RunningStatePB::Stopped,
        lack_of_resource: None,
        plugin_version: None,
      })
      .send();
    }
    Ok(())
  }
}

#[instrument(level = "debug", skip_all, err)]
async fn initialize_ai_plugin(
  plugin: &Arc<OllamaAIPlugin>,
  llm_resource: &Arc<LocalAIResourceController>,
  ret: Option<tokio::sync::oneshot::Sender<()>>,
) -> FlowyResult<()> {
  let lack_of_resource = llm_resource.get_lack_of_resource().await;

  chat_notification_builder(
    APPFLOWY_AI_NOTIFICATION_KEY,
    ChatNotification::UpdateLocalAIState,
  )
  .payload(LocalAIPB {
    enabled: true,
    plugin_downloaded: true,
    state: RunningStatePB::ReadyToRun,
    lack_of_resource: lack_of_resource.clone(),
    plugin_version: None,
  })
  .send();

  if let Some(lack_of_resource) = lack_of_resource {
    info!(
      "[Local AI] lack of resource: {:?} to initialize plugin, thread: {:?}",
      lack_of_resource,
      std::thread::current().id()
    );
    chat_notification_builder(
      APPFLOWY_AI_NOTIFICATION_KEY,
      ChatNotification::LocalAIResourceUpdated,
    )
    .payload(lack_of_resource)
    .send();

    return Ok(());
  }

  if let Err(err) = plugin.destroy_plugin().await {
    error!(
      "[Local AI] failed to destroy plugin when lack of resource: {:?}",
      err
    );
  }

  let plugin = plugin.clone();
  let cloned_llm_res = llm_resource.clone();
  tokio::task::spawn_blocking(move || {
    futures::executor::block_on(async move {
      match cloned_llm_res.get_plugin_config(true).await {
        Ok(config) => {
          info!(
            "[Local AI] initialize plugin with config: {:?}, thread: {:?}",
            config,
            std::thread::current().id()
          );

          match plugin.init_plugin(config).await {
            Ok(_) => {},
            Err(err) => error!("[Local AI] failed to setup plugin: {:?}", err),
          }

          if let Some(ret) = ret {
            let _ = ret.send(());
          }
        },
        Err(err) => {
          error!("[Local AI] failed to get plugin config: {:?}", err);
        },
      };
    })
  });

  Ok(())
}

pub struct LLMResourceServiceImpl {
  store_preferences: Weak<KVStorePreferences>,
}

impl LLMResourceServiceImpl {
  fn upgrade_store_preferences(&self) -> FlowyResult<Arc<KVStorePreferences>> {
    self
      .store_preferences
      .upgrade()
      .ok_or_else(|| FlowyError::internal().with_context("Store preferences is dropped"))
  }
}
#[async_trait]
impl LLMResourceService for LLMResourceServiceImpl {
  fn store_setting(&self, setting: LocalAISetting) -> Result<(), Error> {
    let store_preferences = self.upgrade_store_preferences()?;
    store_preferences.set_object(LOCAL_AI_SETTING_KEY, &setting)?;
    Ok(())
  }

  fn retrieve_setting(&self) -> Option<LocalAISetting> {
    let store_preferences = self.upgrade_store_preferences().ok()?;
    store_preferences.get_object::<LocalAISetting>(LOCAL_AI_SETTING_KEY)
  }
}

const APPFLOWY_LOCAL_AI_ENABLED: &str = "appflowy_local_ai_enabled";
fn local_ai_enabled_key(workspace_id: &str) -> String {
  format!("{}:{}", APPFLOWY_LOCAL_AI_ENABLED, workspace_id)
}

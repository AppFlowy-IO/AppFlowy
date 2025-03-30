use crate::ai_manager::AIUserService;
use crate::entities::{LackOfAIResourcePB, LocalAIPB, RunningStatePB};
use crate::local_ai::resource::{LLMResourceService, LocalAIResourceController};
use crate::notification::{
  chat_notification_builder, ChatNotification, APPFLOWY_AI_NOTIFICATION_KEY,
};
use af_plugin::manager::PluginManager;
use anyhow::Error;
use flowy_ai_pub::cloud::{ChatCloudService, ChatMessageMetadata, ContextLoader, LocalAIConfig};
use flowy_error::{FlowyError, FlowyResult};
use flowy_sqlite::kv::KVStorePreferences;
use futures::Sink;
use lib_infra::async_trait::async_trait;
use std::collections::HashMap;

use crate::local_ai::watch::is_plugin_ready;
use crate::stream_message::StreamMessage;
use af_local_ai::ollama_plugin::OllamaAIPlugin;
use af_plugin::core::plugin::RunningState;
use arc_swap::ArcSwapOption;
use futures_util::SinkExt;
use lib_infra::util::get_operating_system;
use serde::{Deserialize, Serialize};
use serde_json::json;
use std::ops::Deref;
use std::path::{Path, PathBuf};
use std::sync::Arc;
use tokio::select;
use tokio_stream::StreamExt;
use tracing::{debug, error, info, instrument};

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
      chat_model_name: "llama3.1".to_string(),
      embedding_model_name: "nomic-embed-text".to_string(),
    }
  }
}

const LOCAL_AI_SETTING_KEY: &str = "appflowy_local_ai_setting:v1";

pub struct LocalAIController {
  ai_plugin: Arc<OllamaAIPlugin>,
  resource: Arc<LocalAIResourceController>,
  current_chat_id: ArcSwapOption<String>,
  store_preferences: Arc<KVStorePreferences>,
  user_service: Arc<dyn AIUserService>,
  #[allow(dead_code)]
  cloud_service: Arc<dyn ChatCloudService>,
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
    store_preferences: Arc<KVStorePreferences>,
    user_service: Arc<dyn AIUserService>,
    cloud_service: Arc<dyn ChatCloudService>,
  ) -> Self {
    debug!(
      "[AI Plugin] init local ai controller, thread: {:?}",
      std::thread::current().id()
    );

    // Create the core plugin and resource controller
    let local_ai = Arc::new(OllamaAIPlugin::new(plugin_manager));
    let res_impl = LLMResourceServiceImpl {
      user_service: user_service.clone(),
      cloud_service: cloud_service.clone(),
      store_preferences: store_preferences.clone(),
    };
    let local_ai_resource = Arc::new(LocalAIResourceController::new(
      user_service.clone(),
      res_impl,
    ));
    // Subscribe to state changes
    let mut running_state_rx = local_ai.subscribe_running_state();

    let cloned_llm_res = Arc::clone(&local_ai_resource);
    let cloned_store_preferences = Arc::clone(&store_preferences);
    let cloned_local_ai = Arc::clone(&local_ai);
    let cloned_user_service = Arc::clone(&user_service);

    // Spawn a background task to listen for plugin state changes
    tokio::spawn(async move {
      while let Some(state) = running_state_rx.next().await {
        // Skip if we can’t get workspace_id
        let Ok(workspace_id) = cloned_user_service.workspace_id() else {
          continue;
        };

        let key = local_ai_enabled_key(&workspace_id);
        info!("[AI Plugin] state: {:?}", state);

        // Read whether plugin is enabled from store; default to true
        let enabled = cloned_store_preferences.get_bool(&key).unwrap_or(true);

        // Only check resource status if the plugin isn’t in "UnexpectedStop" and is enabled
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
      }
    });

    Self {
      ai_plugin: local_ai,
      resource: local_ai_resource,
      current_chat_id: ArcSwapOption::default(),
      store_preferences,
      user_service,
      cloud_service,
    }
  }
  #[instrument(level = "debug", skip_all)]
  pub async fn observe_plugin_resource(&self) {
    debug!(
      "[AI Plugin] init plugin when first run. thread: {:?}",
      std::thread::current().id()
    );
    let sys = get_operating_system();
    if !sys.is_desktop() {
      return;
    }
    async fn try_init_plugin(
      resource: &Arc<LocalAIResourceController>,
      ai_plugin: &Arc<OllamaAIPlugin>,
    ) {
      if let Err(err) = initialize_ai_plugin(ai_plugin, resource, None).await {
        error!("[AI Plugin] failed to setup plugin: {:?}", err);
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
                info!("[AI Plugin] app state changed, try to init plugin");
                try_init_plugin(&resource_clone, &ai_plugin_clone).await;
            },
            _ = resource_notify.recv() => {
                info!("[AI Plugin] resource changed, try to init plugin");
                try_init_plugin(&resource_clone, &ai_plugin_clone).await;
            },
            else => break,
        }
      }
    });
  }

  pub async fn reload(&self) -> FlowyResult<()> {
    let is_enabled = self.is_enabled();
    self.toggle_plugin(is_enabled).await?;
    Ok(())
  }

  /// Indicate whether the local AI plugin is running.
  pub fn is_running(&self) -> bool {
    if !self.is_enabled() {
      return false;
    }
    self.ai_plugin.get_plugin_running_state().is_running()
  }

  /// Indicate whether the local AI is enabled.
  /// AppFlowy store the value in local storage isolated by workspace id. Each workspace can have
  /// different settings.
  pub fn is_enabled(&self) -> bool {
    if !get_operating_system().is_desktop() {
      return false;
    }

    if let Ok(key) = self
      .user_service
      .workspace_id()
      .map(|workspace_id| local_ai_enabled_key(&workspace_id))
    {
      self.store_preferences.get_bool(&key).unwrap_or(false)
    } else {
      false
    }
  }

  pub fn get_plugin_chat_model(&self) -> Option<String> {
    if !self.is_enabled() {
      return None;
    }
    Some(self.resource.get_llm_setting().chat_model_name)
  }

  pub fn open_chat(&self, chat_id: &str) {
    if !self.is_enabled() {
      return;
    }

    // Only keep one chat open at a time. Since loading multiple models at the same time will cause
    // memory issues.
    if let Some(current_chat_id) = self.current_chat_id.load().as_ref() {
      debug!("[AI Plugin] close previous chat: {}", current_chat_id);
      self.close_chat(current_chat_id);
    }

    self
      .current_chat_id
      .store(Some(Arc::new(chat_id.to_string())));
    let chat_id = chat_id.to_string();
    let weak_ctrl = Arc::downgrade(&self.ai_plugin);
    tokio::spawn(async move {
      if let Some(ctrl) = weak_ctrl.upgrade() {
        if let Err(err) = ctrl.create_chat(&chat_id).await {
          error!("[AI Plugin] failed to open chat: {:?}", err);
        }
      }
    });
  }

  pub fn close_chat(&self, chat_id: &str) {
    if !self.is_running() {
      return;
    }
    info!("[AI Plugin] notify close chat: {}", chat_id);
    let weak_ctrl = Arc::downgrade(&self.ai_plugin);
    let chat_id = chat_id.to_string();
    tokio::spawn(async move {
      if let Some(ctrl) = weak_ctrl.upgrade() {
        if let Err(err) = ctrl.close_chat(&chat_id).await {
          error!("[AI Plugin] failed to close chat: {:?}", err);
        }
      }
    });
  }

  pub fn get_local_ai_setting(&self) -> LocalAISetting {
    self.resource.get_llm_setting()
  }

  pub async fn update_local_ai_setting(&self, setting: LocalAISetting) -> FlowyResult<()> {
    info!(
      "[AI Plugin] update local ai setting: {:?}, thread: {:?}",
      setting,
      std::thread::current().id()
    );
    self.resource.set_llm_setting(setting).await?;
    self.reload().await?;
    Ok(())
  }

  #[instrument(level = "debug", skip_all)]
  pub async fn get_local_ai_state(&self) -> LocalAIPB {
    let start = std::time::Instant::now();
    let enabled = self.is_enabled();

    // If not enabled, return immediately.
    if !enabled {
      debug!(
        "[AI Plugin] get local ai state, elapsed: {:?}, thread: {:?}",
        start.elapsed(),
        std::thread::current().id()
      );
      return LocalAIPB {
        enabled: false,
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
      "[AI Plugin] get local ai state, elapsed: {:?}, thread: {:?}",
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
      error!("[AI Plugin] failed to setup plugin: {:?}", err);
    }
  }

  pub fn get_model_storage_directory(&self) -> FlowyResult<String> {
    self
      .resource
      .user_model_folder()
      .map(|path| path.to_string_lossy().to_string())
  }

  pub async fn get_plugin_download_link(&self) -> FlowyResult<String> {
    self.resource.get_plugin_download_link().await
  }

  pub async fn toggle_local_ai(&self) -> FlowyResult<bool> {
    let workspace_id = self.user_service.workspace_id()?;
    let key = local_ai_enabled_key(&workspace_id);
    let enabled = !self.store_preferences.get_bool(&key).unwrap_or(true);
    self.store_preferences.set_bool(&key, enabled)?;
    self.toggle_plugin(enabled).await?;
    Ok(enabled)
  }

  #[instrument(level = "debug", skip_all)]
  pub async fn index_message_metadata(
    &self,
    chat_id: &str,
    metadata_list: &[ChatMessageMetadata],
    index_process_sink: &mut (impl Sink<String> + Unpin),
  ) -> FlowyResult<()> {
    if !self.is_enabled() {
      info!("[AI Plugin] local ai is disabled, skip indexing");
      return Ok(());
    }

    for metadata in metadata_list {
      let mut file_metadata = HashMap::new();
      file_metadata.insert("id".to_string(), json!(&metadata.id));
      file_metadata.insert("name".to_string(), json!(&metadata.name));
      file_metadata.insert("source".to_string(), json!(&metadata.source));

      let file_path = Path::new(&metadata.data.content);
      if !file_path.exists() {
        return Err(
          FlowyError::record_not_found().with_context(format!("File not found: {:?}", file_path)),
        );
      }
      info!(
        "[AI Plugin] embed file: {:?}, with metadata: {:?}",
        file_path, file_metadata
      );

      match &metadata.data.content_type {
        ContextLoader::Unknown => {
          error!(
            "[AI Plugin] unsupported content type: {:?}",
            metadata.data.content_type
          );
        },
        ContextLoader::Text | ContextLoader::Markdown | ContextLoader::PDF => {
          self
            .process_index_file(
              chat_id,
              file_path.to_path_buf(),
              &file_metadata,
              index_process_sink,
            )
            .await?;
        },
      }
    }

    Ok(())
  }

  async fn process_index_file(
    &self,
    chat_id: &str,
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
      .embed_file(chat_id, file_path, Some(index_metadata.clone()))
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
        error!("[AI Plugin] failed to index file: {:?}", err);
      },
    }

    Ok(())
  }

  #[instrument(level = "debug", skip_all)]
  async fn toggle_plugin(&self, enabled: bool) -> FlowyResult<()> {
    info!(
      "[AI Plugin] enable: {}, thread id: {:?}",
      enabled,
      std::thread::current().id()
    );
    if enabled {
      let (tx, rx) = tokio::sync::oneshot::channel();
      if let Err(err) = initialize_ai_plugin(&self.ai_plugin, &self.resource, Some(tx)).await {
        error!("[AI Plugin] failed to initialize local ai: {:?}", err);
      }
      let _ = rx.await;
    } else {
      if let Err(err) = self.ai_plugin.destroy_plugin().await {
        error!("[AI Plugin] failed to destroy plugin: {:?}", err);
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
      "[AI Plugin] lack of resource: {:?} to initialize plugin, thread: {:?}",
      lack_of_resource,
      std::thread::current().id()
    );
    chat_notification_builder(
      APPFLOWY_AI_NOTIFICATION_KEY,
      ChatNotification::LocalAIResourceUpdated,
    )
    .payload(LackOfAIResourcePB {
      resource_desc: lack_of_resource,
    })
    .send();

    return Ok(());
  }

  if let Err(err) = plugin.destroy_plugin().await {
    error!(
      "[AI Plugin] failed to destroy plugin when lack of resource: {:?}",
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
            "[AI Plugin] initialize plugin with config: {:?}, thread: {:?}",
            config,
            std::thread::current().id()
          );

          match plugin.init_plugin(config).await {
            Ok(_) => {},
            Err(err) => error!("[AI Plugin] failed to setup plugin: {:?}", err),
          }

          if let Some(ret) = ret {
            let _ = ret.send(());
          }
        },
        Err(err) => {
          error!("[AI Plugin] failed to get plugin config: {:?}", err);
        },
      };
    })
  });

  Ok(())
}

pub struct LLMResourceServiceImpl {
  user_service: Arc<dyn AIUserService>,
  cloud_service: Arc<dyn ChatCloudService>,
  store_preferences: Arc<KVStorePreferences>,
}
#[async_trait]
impl LLMResourceService for LLMResourceServiceImpl {
  async fn fetch_local_ai_config(&self) -> Result<LocalAIConfig, anyhow::Error> {
    let workspace_id = self.user_service.workspace_id()?;
    let config = self
      .cloud_service
      .get_local_ai_config(&workspace_id)
      .await?;
    Ok(config)
  }

  fn store_setting(&self, setting: LocalAISetting) -> Result<(), Error> {
    self
      .store_preferences
      .set_object(LOCAL_AI_SETTING_KEY, &setting)?;
    Ok(())
  }

  fn retrieve_setting(&self) -> Option<LocalAISetting> {
    self
      .store_preferences
      .get_object::<LocalAISetting>(LOCAL_AI_SETTING_KEY)
  }
}

const APPFLOWY_LOCAL_AI_ENABLED: &str = "appflowy_local_ai_enabled";
fn local_ai_enabled_key(workspace_id: &str) -> String {
  format!("{}:{}", APPFLOWY_LOCAL_AI_ENABLED, workspace_id)
}

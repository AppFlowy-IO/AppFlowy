use crate::ai_manager::AIUserService;
use crate::entities::{LocalAIPluginStatePB, LocalModelResourcePB, RunningStatePB};
use crate::local_ai::local_llm_resource::{LLMResourceService, LocalAIResourceController};
use crate::notification::{make_notification, ChatNotification, APPFLOWY_AI_NOTIFICATION_KEY};
use anyhow::Error;
use appflowy_local_ai::chat_plugin::{AIPluginConfig, AppFlowyLocalAI};
use appflowy_plugin::manager::PluginManager;
use appflowy_plugin::util::is_apple_silicon;
use flowy_ai_pub::cloud::{
  AppFlowyOfflineAI, ChatCloudService, ChatMessageMetadata, ChatMetadataContentType, LLMModel,
  LocalAIConfig,
};
use flowy_error::{FlowyError, FlowyResult};
use flowy_sqlite::kv::KVStorePreferences;
use futures::Sink;
use lib_infra::async_trait::async_trait;
use std::collections::HashMap;

use crate::stream_message::StreamMessage;
use futures_util::SinkExt;
use parking_lot::Mutex;
use serde::{Deserialize, Serialize};
use serde_json::json;
use std::ops::Deref;
use std::path::{Path, PathBuf};
use std::sync::Arc;
use tokio::select;
use tokio_stream::StreamExt;
use tracing::{debug, error, info, instrument, trace};

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct LLMSetting {
  pub app: AppFlowyOfflineAI,
  pub llm_model: LLMModel,
}

pub struct LLMModelInfo {
  pub selected_model: LLMModel,
  pub models: Vec<LLMModel>,
}

const APPFLOWY_LOCAL_AI_ENABLED: &str = "appflowy_local_ai_enabled";
const APPFLOWY_LOCAL_AI_CHAT_ENABLED: &str = "appflowy_local_ai_chat_enabled";
const APPFLOWY_LOCAL_AI_CHAT_RAG_ENABLED: &str = "appflowy_local_ai_chat_rag_enabled";
const LOCAL_AI_SETTING_KEY: &str = "appflowy_local_ai_setting:v0";

pub struct LocalAIController {
  local_ai: Arc<AppFlowyLocalAI>,
  local_ai_resource: Arc<LocalAIResourceController>,
  current_chat_id: Mutex<Option<String>>,
  store_preferences: Arc<KVStorePreferences>,
}

impl Deref for LocalAIController {
  type Target = Arc<AppFlowyLocalAI>;

  fn deref(&self) -> &Self::Target {
    &self.local_ai
  }
}

impl LocalAIController {
  pub fn new(
    plugin_manager: Arc<PluginManager>,
    store_preferences: Arc<KVStorePreferences>,
    user_service: Arc<dyn AIUserService>,
    cloud_service: Arc<dyn ChatCloudService>,
  ) -> Self {
    let local_ai = Arc::new(AppFlowyLocalAI::new(plugin_manager));
    let res_impl = LLMResourceServiceImpl {
      user_service: user_service.clone(),
      cloud_service,
      store_preferences: store_preferences.clone(),
    };

    let (tx, mut rx) = tokio::sync::mpsc::channel(1);
    let llm_res = Arc::new(LocalAIResourceController::new(user_service, res_impl, tx));
    let current_chat_id = Mutex::new(None);

    let mut running_state_rx = local_ai.subscribe_running_state();
    let cloned_llm_res = llm_res.clone();
    tokio::spawn(async move {
      while let Some(state) = running_state_rx.next().await {
        info!("[AI Plugin] state: {:?}", state);
        let offline_ai_ready = cloned_llm_res.is_offline_app_ready();
        let new_state = RunningStatePB::from(state);
        make_notification(
          APPFLOWY_AI_NOTIFICATION_KEY,
          ChatNotification::UpdateChatPluginState,
        )
        .payload(LocalAIPluginStatePB {
          state: new_state,
          offline_ai_ready,
        })
        .send();
      }
    });

    let this = Self {
      local_ai,
      local_ai_resource: llm_res,
      current_chat_id,
      store_preferences,
    };

    let rag_enabled = this.is_rag_enabled();
    let cloned_llm_chat = this.local_ai.clone();
    let cloned_llm_res = this.local_ai_resource.clone();
    let mut offline_ai_watch = this.local_ai_resource.subscribe_offline_app_state();
    tokio::spawn(async move {
      let init_fn = || {
        if let Ok(chat_config) = cloned_llm_res.get_chat_config(rag_enabled) {
          if let Err(err) = initialize_ai_plugin(&cloned_llm_chat, chat_config, None) {
            error!("[AI Plugin] failed to setup plugin: {:?}", err);
          }
        }
      };

      loop {
        select! {
          _ = offline_ai_watch.recv() => {
              init_fn();
          },
          _ = rx.recv() => {
              init_fn();
          },
          else => { break; }
        }
      }
    });

    if this.can_init_plugin() {
      let result = this
        .local_ai_resource
        .get_chat_config(this.is_rag_enabled());
      if let Ok(chat_config) = result {
        if let Err(err) = initialize_ai_plugin(&this.local_ai, chat_config, None) {
          error!("[AI Plugin] failed to setup plugin: {:?}", err);
        }
      }
    }

    this
  }
  pub async fn refresh(&self) -> FlowyResult<LLMModelInfo> {
    self.local_ai_resource.refresh_llm_resource().await
  }

  /// Returns true if the local AI is enabled and ready to use.
  pub fn can_init_plugin(&self) -> bool {
    self.is_enabled() && self.local_ai_resource.is_resource_ready()
  }

  /// Indicate whether the local AI plugin is running.
  pub fn is_running(&self) -> bool {
    self.local_ai.get_plugin_running_state().is_ready()
  }

  /// Indicate whether the local AI is enabled.
  pub fn is_enabled(&self) -> bool {
    self
      .store_preferences
      .get_bool(APPFLOWY_LOCAL_AI_ENABLED)
      .unwrap_or(true)
  }

  /// Indicate whether the local AI chat is enabled. In the future, we can support multiple
  /// AI plugin.
  pub fn is_chat_enabled(&self) -> bool {
    self
      .store_preferences
      .get_bool(APPFLOWY_LOCAL_AI_CHAT_ENABLED)
      .unwrap_or(true)
  }

  pub fn is_rag_enabled(&self) -> bool {
    self
      .store_preferences
      .get_bool(APPFLOWY_LOCAL_AI_CHAT_RAG_ENABLED)
      .unwrap_or(true)
  }

  pub fn open_chat(&self, chat_id: &str) {
    if !self.is_enabled() {
      return;
    }

    // Only keep one chat open at a time. Since loading multiple models at the same time will cause
    // memory issues.
    if let Some(current_chat_id) = self.current_chat_id.lock().as_ref() {
      debug!("[AI Plugin] close previous chat: {}", current_chat_id);
      self.close_chat(current_chat_id);
    }

    *self.current_chat_id.lock() = Some(chat_id.to_string());
    let chat_id = chat_id.to_string();
    let weak_ctrl = Arc::downgrade(&self.local_ai);
    tokio::spawn(async move {
      if let Some(ctrl) = weak_ctrl.upgrade() {
        if let Err(err) = ctrl.create_chat(&chat_id).await {
          error!("[AI Plugin] failed to open chat: {:?}", err);
        }
      }
    });
  }

  pub fn close_chat(&self, chat_id: &str) {
    let weak_ctrl = Arc::downgrade(&self.local_ai);
    let chat_id = chat_id.to_string();
    tokio::spawn(async move {
      if let Some(ctrl) = weak_ctrl.upgrade() {
        if let Err(err) = ctrl.close_chat(&chat_id).await {
          error!("[AI Plugin] failed to close chat: {:?}", err);
        }
      }
    });
  }

  pub async fn select_local_llm(&self, llm_id: i64) -> FlowyResult<LocalModelResourcePB> {
    if !self.is_enabled() {
      return Err(FlowyError::local_ai_unavailable());
    }

    if let Some(model) = self.local_ai_resource.get_selected_model() {
      if model.llm_id == llm_id {
        return self.local_ai_resource.get_local_llm_state();
      }
    }

    let state = self.local_ai_resource.use_local_llm(llm_id)?;
    // Re-initialize the plugin if the setting is updated and ready to use
    if self.local_ai_resource.is_resource_ready() {
      let chat_config = self
        .local_ai_resource
        .get_chat_config(self.is_rag_enabled())?;
      if let Err(err) = initialize_ai_plugin(&self.local_ai, chat_config, None) {
        error!("failed to setup plugin: {:?}", err);
      }
    }
    Ok(state)
  }

  pub async fn get_local_llm_state(&self) -> FlowyResult<LocalModelResourcePB> {
    self.local_ai_resource.get_local_llm_state()
  }

  pub fn get_current_model(&self) -> Option<LLMModel> {
    self.local_ai_resource.get_selected_model()
  }

  pub async fn start_downloading<T>(&self, progress_sink: T) -> FlowyResult<String>
  where
    T: Sink<String, Error = anyhow::Error> + Unpin + Sync + Send + 'static,
  {
    let task_id = self
      .local_ai_resource
      .start_downloading(progress_sink)
      .await?;
    Ok(task_id)
  }

  pub fn cancel_download(&self) -> FlowyResult<()> {
    self.local_ai_resource.cancel_download()?;
    Ok(())
  }

  pub fn get_chat_plugin_state(&self) -> LocalAIPluginStatePB {
    let offline_ai_ready = self.local_ai_resource.is_offline_app_ready();
    let state = self.local_ai.get_plugin_running_state();
    LocalAIPluginStatePB {
      state: RunningStatePB::from(state),
      offline_ai_ready,
    }
  }

  pub fn restart_chat_plugin(&self) {
    let rag_enabled = self.is_rag_enabled();
    if let Ok(chat_config) = self.local_ai_resource.get_chat_config(rag_enabled) {
      if let Err(err) = initialize_ai_plugin(&self.local_ai, chat_config, None) {
        error!("[AI Plugin] failed to setup plugin: {:?}", err);
      }
    }
  }

  pub fn get_model_storage_directory(&self) -> FlowyResult<String> {
    self
      .local_ai_resource
      .user_model_folder()
      .map(|path| path.to_string_lossy().to_string())
  }

  pub async fn get_offline_ai_app_download_link(&self) -> FlowyResult<String> {
    self
      .local_ai_resource
      .get_offline_ai_app_download_link()
      .await
  }

  pub async fn toggle_local_ai(&self) -> FlowyResult<bool> {
    let enabled = !self
      .store_preferences
      .get_bool(APPFLOWY_LOCAL_AI_ENABLED)
      .unwrap_or(true);
    self
      .store_preferences
      .set_bool(APPFLOWY_LOCAL_AI_ENABLED, enabled)?;

    // when enable local ai. we need to check if chat is enabled, if enabled, we need to init chat plugin
    // otherwise, we need to destroy the plugin
    if enabled {
      let chat_enabled = self
        .store_preferences
        .get_bool(APPFLOWY_LOCAL_AI_CHAT_ENABLED)
        .unwrap_or(true);
      self.enable_chat_plugin(chat_enabled).await?;
    } else {
      self.enable_chat_plugin(false).await?;
    }
    Ok(enabled)
  }

  pub async fn toggle_local_ai_chat(&self) -> FlowyResult<bool> {
    let enabled = !self
      .store_preferences
      .get_bool(APPFLOWY_LOCAL_AI_CHAT_ENABLED)
      .unwrap_or(true);
    self
      .store_preferences
      .set_bool(APPFLOWY_LOCAL_AI_CHAT_ENABLED, enabled)?;
    self.enable_chat_plugin(enabled).await?;

    Ok(enabled)
  }

  pub async fn toggle_local_ai_chat_rag(&self) -> FlowyResult<bool> {
    let enabled = !self
      .store_preferences
      .get_bool_or_default(APPFLOWY_LOCAL_AI_CHAT_RAG_ENABLED);
    self
      .store_preferences
      .set_bool(APPFLOWY_LOCAL_AI_CHAT_RAG_ENABLED, enabled)?;
    Ok(enabled)
  }
  pub async fn index_message_metadata(
    &self,
    chat_id: &str,
    metadata_list: &[ChatMessageMetadata],
    index_process_sink: &mut (impl Sink<String> + Unpin),
  ) -> FlowyResult<()> {
    for metadata in metadata_list {
      if let Err(err) = metadata.data.validate() {
        error!(
          "[AI Plugin] invalid metadata: {:?}, error: {:?}",
          metadata, err
        );
        continue;
      }

      let mut index_metadata = HashMap::new();
      index_metadata.insert("name".to_string(), json!(&metadata.name));
      index_metadata.insert("at_name".to_string(), json!(format!("@{}", &metadata.name)));
      index_metadata.insert("source".to_string(), json!(&metadata.source));
      match &metadata.data.content_type {
        ChatMetadataContentType::Unknown => {
          error!(
            "[AI Plugin] unsupported content type: {:?}",
            metadata.data.content_type
          );
        },
        ChatMetadataContentType::Text | ChatMetadataContentType::Markdown => {
          trace!("[AI Plugin]: index text: {}", metadata.data.content);
          self
            .process_index_file(
              chat_id,
              None,
              Some(metadata.data.content.clone()),
              metadata,
              &index_metadata,
              index_process_sink,
            )
            .await?;
        },
        ChatMetadataContentType::PDF => {
          trace!("[AI Plugin]: index pdf file: {}", metadata.data.content);
          let file_path = Path::new(&metadata.data.content);
          if file_path.exists() {
            self
              .process_index_file(
                chat_id,
                Some(file_path.to_path_buf()),
                None,
                metadata,
                &index_metadata,
                index_process_sink,
              )
              .await?;
          }
        },
      }
    }

    Ok(())
  }

  async fn process_index_file(
    &self,
    chat_id: &str,
    file_path: Option<PathBuf>,
    content: Option<String>,
    metadata: &ChatMessageMetadata,
    index_metadata: &HashMap<String, serde_json::Value>,
    index_process_sink: &mut (impl Sink<String> + Unpin),
  ) -> Result<(), FlowyError> {
    let _ = index_process_sink
      .send(
        StreamMessage::StartIndexFile {
          file_name: metadata.name.clone(),
        }
        .to_string(),
      )
      .await;

    let result = self
      .index_file(chat_id, file_path, content, Some(index_metadata.clone()))
      .await;
    match result {
      Ok(_) => {
        let _ = index_process_sink
          .send(
            StreamMessage::EndIndexFile {
              file_name: metadata.name.clone(),
            }
            .to_string(),
          )
          .await;
      },
      Err(err) => {
        let _ = index_process_sink
          .send(
            StreamMessage::IndexFileError {
              file_name: metadata.name.clone(),
            }
            .to_string(),
          )
          .await;
        error!("[AI Plugin] failed to index file: {:?}", err);
      },
    }

    Ok(())
  }

  async fn enable_chat_plugin(&self, enabled: bool) -> FlowyResult<()> {
    info!("[AI Plugin] enable chat plugin: {}", enabled);
    if enabled {
      let (tx, rx) = tokio::sync::oneshot::channel();
      let chat_config = self
        .local_ai_resource
        .get_chat_config(self.is_rag_enabled())?;
      if let Err(err) = initialize_ai_plugin(&self.local_ai, chat_config, Some(tx)) {
        error!("[AI Plugin] failed to initialize local ai: {:?}", err);
      }
      let _ = rx.await;
    } else if let Err(err) = self.local_ai.destroy_chat_plugin().await {
      error!("[AI Plugin] failed to destroy plugin: {:?}", err);
    }
    Ok(())
  }
}

#[instrument(level = "debug", skip_all, err)]
fn initialize_ai_plugin(
  llm_chat: &Arc<AppFlowyLocalAI>,
  mut chat_config: AIPluginConfig,
  ret: Option<tokio::sync::oneshot::Sender<()>>,
) -> FlowyResult<()> {
  let llm_chat = llm_chat.clone();

  tokio::spawn(async move {
    info!("[AI Plugin] config: {:?}", chat_config);
    if is_apple_silicon().await.unwrap_or(false) {
      chat_config = chat_config.with_device("gpu");
    }
    match llm_chat.init_chat_plugin(chat_config).await {
      Ok(_) => {},
      Err(err) => error!("[AI Plugin] failed to setup plugin: {:?}", err),
    }

    if let Some(ret) = ret {
      let _ = ret.send(());
    }
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

  fn store_setting(&self, setting: LLMSetting) -> Result<(), Error> {
    self
      .store_preferences
      .set_object(LOCAL_AI_SETTING_KEY, setting)?;
    Ok(())
  }

  fn retrieve_setting(&self) -> Option<LLMSetting> {
    self
      .store_preferences
      .get_object::<LLMSetting>(LOCAL_AI_SETTING_KEY)
  }

  fn is_rag_enabled(&self) -> bool {
    self
      .store_preferences
      .get_bool_or_default(APPFLOWY_LOCAL_AI_CHAT_RAG_ENABLED)
  }
}

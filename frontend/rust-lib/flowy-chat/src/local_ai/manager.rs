use crate::local_ai::chat_plugin::ChatPluginOperation;
use bytes::Bytes;
use dashmap::DashMap;
use flowy_error::{FlowyError, FlowyResult};
use flowy_sidecar::core::plugin::{PluginId, PluginInfo};
use flowy_sidecar::error::SidecarError;
use flowy_sidecar::manager::SidecarManager;
use log::error;
use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use std::sync::Arc;
use tokio::sync::RwLock;
use tokio_stream::wrappers::ReceiverStream;
use tracing::{debug, trace};

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct LocalAISetting {
  pub bin_dir: String,
  pub chat_bin: String,
  pub chat_model: String,
  pub enabled: bool,
}

impl LocalAISetting {
  pub fn validate(&self) -> FlowyResult<()> {
    ChatPluginConfig::new(&self.bin_dir, &self.chat_bin, &self.chat_model)?;
    Ok(())
  }
  pub fn get_chat_plugin_config(&self) -> FlowyResult<ChatPluginConfig> {
    let config = ChatPluginConfig::new(&self.bin_dir, &self.chat_bin, &self.chat_model)?;
    Ok(config)
  }
}

pub struct LocalAIManager {
  sidecar_manager: Arc<SidecarManager>,
  chat_plugin_config: RwLock<Option<ChatPluginConfig>>,
  plugin_map: DashMap<PathBuf, PluginId>,
  chat_plugin_id: RwLock<Option<PluginId>>,
}

impl LocalAIManager {
  pub fn new(sidecar_manager: Arc<SidecarManager>) -> Self {
    Self {
      sidecar_manager,
      chat_plugin_config: RwLock::new(None),
      plugin_map: Default::default(),
      chat_plugin_id: Default::default(),
    }
  }

  pub async fn ask_question(
    &self,
    chat_id: &str,
    message: &str,
  ) -> FlowyResult<ReceiverStream<anyhow::Result<Bytes, SidecarError>>> {
    let plugin_id = self
      .chat_plugin_id
      .read()
      .await
      .ok_or_else(|| FlowyError::local_ai().with_context("chat plugin not set"))?;

    let plugin = self.sidecar_manager.get_plugin(plugin_id).await?;

    let operation = ChatPluginOperation::new(plugin);
    let stream = operation.stream_message(chat_id, message).await?;
    Ok(stream)
  }

  pub async fn generate_answer(&self, chat_id: &str, message: &str) -> FlowyResult<String> {
    let plugin_id = self
      .chat_plugin_id
      .read()
      .await
      .ok_or_else(|| FlowyError::local_ai().with_context("chat plugin not set"))?;

    let plugin = self.sidecar_manager.get_plugin(plugin_id).await?;

    let operation = ChatPluginOperation::new(plugin);
    let answer = operation.send_message(chat_id, message).await?;
    Ok(answer)
  }

  pub async fn setup_chat_plugin(&self, config: ChatPluginConfig) -> FlowyResult<()> {
    debug!("setup chat plugin: {:?}", config);
    // If the chat_bin_path is different, remove the old plugin
    if let Some(chat_plugin_config) = self.chat_plugin_config.read().await.as_ref() {
      if chat_plugin_config.chat_bin_path != config.chat_bin_path {
        trace!("remove old plugin: {:?}", chat_plugin_config.chat_bin_path);
        if let Some(entry) = self.plugin_map.remove(&chat_plugin_config.chat_bin_path) {
          if let Err(err) = self.sidecar_manager.remove_plugin(entry.1).await {
            error!("remove plugin failed: {:?}", err);
          }
        }
      }
    }

    // create new plugin
    let plugin_info = PluginInfo {
      name: "chat_plugin".to_string(),
      exec_path: config.chat_bin_path.clone(),
    };
    let plugin = self
      .sidecar_manager
      .create_plugin(plugin_info)
      .await
      .unwrap();

    // init plugin
    let model_path = config.chat_model_path;
    self.sidecar_manager.init_plugin(
      plugin,
      serde_json::json!({
        "absolute_chat_model_path": model_path,
      }),
    )?;

    self.chat_plugin_id.write().await.replace(plugin);
    self.plugin_map.insert(config.chat_bin_path, plugin);
    Ok(())
  }
}

#[derive(Debug, Clone)]
pub struct ChatPluginConfig {
  bin_dir: PathBuf,
  chat_bin_path: PathBuf,
  chat_model_path: PathBuf,
}

impl ChatPluginConfig {
  pub fn new(bin_dir: &str, chat_bin: &str, chat_model_name: &str) -> FlowyResult<Self> {
    // check bin_dir exists and is a directory
    let bin_dir = PathBuf::from(bin_dir);
    if !bin_dir.exists() {
      return Err(
        FlowyError::invalid_data().with_context(format!("bin path not exists: {:?}", bin_dir)),
      );
    }
    if !bin_dir.is_dir() {
      return Err(
        FlowyError::invalid_data()
          .with_context(format!("bin path is not directory: {:?}", bin_dir)),
      );
    }

    let chat_bin_path = bin_dir.join(chat_bin);
    if !chat_bin_path.exists() {
      return Err(FlowyError::invalid_data().with_context(format!(
        "Chat binary path does not exist: {:?}",
        chat_bin_path
      )));
    }
    if !chat_bin_path.is_file() {
      return Err(FlowyError::invalid_data().with_context(format!(
        "Chat binary path is not a file: {:?}",
        chat_bin_path
      )));
    }

    // Check if local_model_dir exists and is a directory
    let chat_model_path = bin_dir.join(&chat_model_name);
    if !chat_model_path.exists() {
      return Err(
        FlowyError::invalid_data()
          .with_context(format!("Local model does not exist: {:?}", chat_model_path)),
      );
    }
    if !chat_model_path.is_file() {
      return Err(
        FlowyError::invalid_data()
          .with_context(format!("Local model is not a file: {:?}", chat_model_path)),
      );
    }

    Ok(Self {
      bin_dir,
      chat_bin_path,
      chat_model_path,
    })
  }
}

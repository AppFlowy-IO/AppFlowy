use crate::local_ai::chat_plugin::ChatPluginOperation;
use bytes::Bytes;
use dashmap::DashMap;
use flowy_error::{FlowyError, FlowyResult};
use flowy_sidecar::core::plugin::{Plugin, PluginId, PluginInfo};
use flowy_sidecar::error::SidecarError;
use flowy_sidecar::manager::SidecarManager;
use log::error;
use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use std::sync::{Arc, Weak};
use tokio::sync::RwLock;
use tokio_stream::wrappers::ReceiverStream;
use tracing::{info, instrument, trace};

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct LocalLLMSetting {
  pub chat_bin_path: String,
  pub chat_model_path: String,
  pub enabled: bool,
}

impl LocalLLMSetting {
  pub fn validate(&self) -> FlowyResult<()> {
    ChatPluginConfig::new(&self.chat_bin_path, &self.chat_model_path)?;
    Ok(())
  }
  pub fn chat_plugin_config(&self) -> FlowyResult<ChatPluginConfig> {
    let config = ChatPluginConfig::new(&self.chat_bin_path, &self.chat_model_path)?;
    Ok(config)
  }
}

pub struct LocalChatLLMController {
  sidecar_manager: Arc<SidecarManager>,
  chat_plugin_config: RwLock<Option<ChatPluginConfig>>,
  plugin_map: DashMap<PathBuf, PluginId>,
  chat_plugin_id: RwLock<Option<PluginId>>,
}

impl LocalChatLLMController {
  pub fn new(sidecar_manager: Arc<SidecarManager>) -> Self {
    Self {
      sidecar_manager,
      chat_plugin_config: RwLock::new(None),
      plugin_map: Default::default(),
      chat_plugin_id: Default::default(),
    }
  }

  async fn get_chat_plugin(&self) -> FlowyResult<Weak<Plugin>> {
    let plugin_id = self
      .chat_plugin_id
      .read()
      .await
      .ok_or_else(|| FlowyError::local_ai().with_context("chat plugin not set"))?;
    let plugin = self.sidecar_manager.get_plugin(plugin_id).await?;
    Ok(plugin)
  }

  pub async fn create_chat(&self, chat_id: &str) -> FlowyResult<()> {
    trace!("[Chat Plugin] create chat: {}", chat_id);
    let plugin = self.get_chat_plugin().await?;
    let operation = ChatPluginOperation::new(plugin);
    operation.create_chat(chat_id).await?;
    Ok(())
  }

  pub async fn close_chat(&self, chat_id: &str) -> FlowyResult<()> {
    trace!("[Chat Plugin] close chat: {}", chat_id);
    let plugin = self.get_chat_plugin().await?;
    let operation = ChatPluginOperation::new(plugin);
    operation.close_chat(chat_id).await?;
    Ok(())
  }

  pub async fn ask_question(
    &self,
    chat_id: &str,
    message: &str,
  ) -> FlowyResult<ReceiverStream<anyhow::Result<Bytes, SidecarError>>> {
    trace!("[Chat Plugin] ask question: {}", message);
    let plugin = self.get_chat_plugin().await?;
    let operation = ChatPluginOperation::new(plugin);
    let stream = operation.stream_message(chat_id, message).await?;
    Ok(stream)
  }

  pub async fn generate_answer(&self, chat_id: &str, message: &str) -> FlowyResult<String> {
    let plugin = self.get_chat_plugin().await?;
    let operation = ChatPluginOperation::new(plugin);
    let answer = operation.send_message(chat_id, message).await?;
    Ok(answer)
  }

  #[instrument(skip_all, err)]
  pub async fn destroy_chat_plugin(&self) -> FlowyResult<()> {
    if let Some(plugin_config) = self.chat_plugin_config.read().await.as_ref() {
      info!("[Chat Plugin] destroy chat plugin: {:?}", plugin_config);
      if let Some(entry) = self.plugin_map.remove(&plugin_config.chat_bin_path) {
        if let Err(err) = self.sidecar_manager.remove_plugin(entry.1).await {
          error!("remove plugin failed: {:?}", err);
        }
      }
    }
    Ok(())
  }

  #[instrument(skip_all, err)]
  pub async fn init_chat_plugin(&self, config: ChatPluginConfig) -> FlowyResult<()> {
    if self.chat_plugin_id.read().await.is_some() {
      if let Some(existing_config) = self.chat_plugin_config.read().await.as_ref() {
        if existing_config == &config {
          return Ok(());
        }
      }
    }

    // Initialize chat plugin if the config is different
    // If the chat_bin_path is different, remove the old plugin
    self.destroy_chat_plugin().await?;

    // create new plugin
    trace!("[Chat Plugin] create chat plugin: {:?}", config);
    let plugin_info = PluginInfo {
      name: "chat_plugin".to_string(),
      exec_path: config.chat_bin_path.clone(),
    };
    let plugin_id = self.sidecar_manager.create_plugin(plugin_info).await?;

    // init plugin
    trace!("[Chat Plugin] init chat plugin model: {:?}", plugin_id);
    let model_path = config.chat_model_path;
    let plugin = self.sidecar_manager.init_plugin(
      plugin_id,
      serde_json::json!({
        "absolute_chat_model_path": model_path,
      }),
    )?;

    info!("[Chat Plugin] {} setup success", plugin);
    self.chat_plugin_id.write().await.replace(plugin_id);
    self.plugin_map.insert(config.chat_bin_path, plugin_id);
    Ok(())
  }
}

#[derive(Eq, PartialEq, Debug, Clone)]
pub struct ChatPluginConfig {
  chat_bin_path: PathBuf,
  chat_model_path: PathBuf,
}

impl ChatPluginConfig {
  pub fn new(chat_bin: &str, chat_model_path: &str) -> FlowyResult<Self> {
    let chat_bin_path = PathBuf::from(chat_bin);
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
    let chat_model_path = PathBuf::from(&chat_model_path);
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
      chat_bin_path,
      chat_model_path,
    })
  }
}

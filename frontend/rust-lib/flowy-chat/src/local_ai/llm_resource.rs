use reqwest::{Client, Response, StatusCode};
use sha2::{Digest, Sha256};

use crate::chat_manager::ChatUserService;
use crate::entities::LocalModelStatePB;
use crate::local_ai::local_llm_chat::{LLMModelInfo, LLMSetting};
use crate::notification::{send_notification, ChatNotification};
use anyhow::anyhow;
use appflowy_local_ai::llm_chat::ChatPluginConfig;
use base64::engine::general_purpose::STANDARD;
use base64::Engine;
use flowy_chat_pub::cloud::{LLMModel, LocalAIConfig};
use flowy_error::{FlowyError, FlowyResult};
use lib_infra::async_trait::async_trait;
use parking_lot::RwLock;
use std::path::{Path, PathBuf};
use std::sync::Arc;
use tokio::fs::{self, File};
use tokio::io::SeekFrom;
use tokio::io::{AsyncReadExt, AsyncSeekExt, AsyncWriteExt};
use tracing::{debug, info, instrument, trace};

#[async_trait]
pub trait LLMResourceService: Send + Sync + 'static {
  async fn get_local_ai_config(&self) -> Result<LocalAIConfig, anyhow::Error>;
  fn store(&self, setting: LLMSetting) -> Result<(), anyhow::Error>;
  fn retrieve(&self) -> Option<LLMSetting>;
}

pub struct LLMResourceController {
  client: Client,
  user_service: Arc<dyn ChatUserService>,
  resource_service: Arc<dyn LLMResourceService>,
  llm_setting: RwLock<Option<LLMSetting>>,
  // The ai_config will be set when user try to get latest local ai config from server
  ai_config: RwLock<Option<LocalAIConfig>>,
}

impl LLMResourceController {
  pub fn new(
    user_service: Arc<dyn ChatUserService>,
    resource_service: impl LLMResourceService,
  ) -> Self {
    let llm_setting = RwLock::new(resource_service.retrieve());
    Self {
      client: Client::new(),
      user_service,
      resource_service: Arc::new(resource_service),
      llm_setting,
      ai_config: Default::default(),
    }
  }

  /// Returns true when all resources are downloaded and ready to use.
  pub fn is_ready(&self) -> bool {
    self.is_resource_ready().unwrap_or(false)
  }

  #[instrument(level = "debug", skip_all, err)]
  pub async fn model_info(&self) -> FlowyResult<LLMModelInfo> {
    let ai_config = self
      .resource_service
      .get_local_ai_config()
      .await
      .map_err(|err| {
        FlowyError::local_ai().with_context(format!("Can't retrieve model info:{}", err))
      })?;

    if ai_config.models.is_empty() {
      return Err(FlowyError::local_ai().with_context("No model found"));
    }

    *self.ai_config.write() = Some(ai_config.clone());
    let selected_config = ai_config.models[0].clone();
    Ok(LLMModelInfo {
      selected_model: selected_config,
      models: ai_config.models,
    })
  }

  #[instrument(level = "info", skip_all, err)]
  pub fn use_local_llm(&self, llm_id: i64) -> FlowyResult<LocalModelStatePB> {
    let (package, llm_config) = self
      .ai_config
      .read()
      .as_ref()
      .and_then(|config| {
        config
          .models
          .iter()
          .find(|model| model.llm_id == llm_id)
          .cloned()
          .map(|model| (config.plugin.clone(), model))
      })
      .ok_or_else(|| FlowyError::local_ai().with_context("No local ai config found"))?;

    let llm_setting = LLMSetting {
      plugin: package,
      llm_model: llm_config.clone(),
    };

    trace!("Selected local ai setting: {:?}", llm_setting);
    *self.llm_setting.write() = Some(llm_setting.clone());
    self.resource_service.store(llm_setting)?;
    self.get_local_llm_state()
  }

  pub fn get_local_llm_state(&self) -> FlowyResult<LocalModelStatePB> {
    let state = self
      .check_resource()
      .ok_or_else(|| FlowyError::local_ai().with_context("No local ai config found"))?;
    Ok(state)
  }

  #[instrument(level = "debug", skip_all)]
  fn check_resource(&self) -> Option<LocalModelStatePB> {
    trace!("Checking local ai resources");
    let llm_model = self
      .llm_setting
      .read()
      .as_ref()
      .map(|setting| setting.llm_model.clone())?;
    let need_download = !self.is_resource_ready().ok()?;
    let payload = LocalModelStatePB {
      model_name: llm_model.chat_model.name,
      model_size: bytes_to_readable_size(llm_model.chat_model.file_size as u64),
      need_download,
      requirements: llm_model.chat_model.requirements,
    };

    if need_download {
      info!("Local AI resources are not ready, notify client to download ai resources");
      // notify client it needs to download ai resource
      send_notification("local_ai_resource", ChatNotification::LocalAIResourceNeeded)
        .payload(payload.clone())
        .send();
    }
    debug!("Local AI resources state: {:?}", payload);
    Some(payload)
  }

  /// Returns true when all resources are downloaded and ready to use.
  pub fn is_resource_ready(&self) -> FlowyResult<bool> {
    match self.llm_setting.read().as_ref() {
      None => Err(FlowyError::local_ai().with_context("Can't find any llm config")),
      Some(llm_setting) => {
        let llm_dir = self.user_service.user_data_dir()?;

        let plugin_needed = should_download_plugin(&llm_dir, llm_setting);
        if plugin_needed {
          return Ok(false);
        }

        let model_needed = should_download_model(&llm_dir, llm_setting);
        if model_needed {
          return Ok(false);
        }

        Ok(false)
      },
    }
  }

  pub fn start_downloading(&self) -> FlowyResult<String> {
    info!("Start downloading local ai resources");
    //
    Ok("".to_string())
  }

  pub fn cancel_download(&self, task_id: &str) -> FlowyResult<()> {
    Ok(())
  }

  pub fn get_chat_config(&self) -> FlowyResult<ChatPluginConfig> {
    if !self.is_resource_ready()? {
      let _ = self.check_resource();
      return Err(FlowyError::local_ai().with_context("Local AI resources are not ready"));
    }

    // let mut config = ChatPluginConfig::new(
    //   setting.chat_bin_path.clone(),
    //   setting.chat_model_path.clone(),
    // )?;
    //
    // let persist_directory = user_data_dir.join("chat_plugin_rag");
    // if !persist_directory.exists() {
    //   std::fs::create_dir_all(&persist_directory)?;
    // }
    //
    // // Enable RAG when the embedding model path is set
    // if let Err(err) = config.set_rag_enabled(
    //   &PathBuf::from(&setting.embedding_model_path),
    //   &persist_directory,
    // ) {
    //   error!(
    //   "[Chat Plugin] failed to enable rag: {:?}, embedding_model_path: {:?}",
    //   err, setting.embedding_model_path
    // );
    // }
    //
    // if cfg!(debug_assertions) {
    //   config = config.with_verbose(true);
    // }
    // Ok(config)
    todo!()
  }

  fn llm_dir(&self) -> FlowyResult<PathBuf> {
    let user_data_dir = self.user_service.user_data_dir()?;
    Ok(user_data_dir.join("llm"))
  }
}

pub fn should_download_plugin(llm_dir: &PathBuf, llm_setting: &LLMSetting) -> bool {
  let plugin_path = llm_dir.join(format!(
    "{}-{}",
    llm_setting.plugin.version, llm_setting.plugin.name
  ));
  !plugin_path.exists()
}

pub fn should_download_model(llm_dir: &PathBuf, llm_setting: &LLMSetting) -> bool {
  let chat_model = llm_dir.join(&llm_setting.llm_model.chat_model.file_name);
  if !chat_model.exists() {
    return true;
  }

  let embedding_model = llm_dir.join(&llm_setting.llm_model.embedding_model.file_name);
  if !embedding_model.exists() {
    return true;
  }

  false
}

pub fn bytes_to_readable_size(bytes: u64) -> String {
  const GB: u64 = 1_000_000_000;
  const MB: u64 = 1_000_000;

  if bytes >= GB {
    let size_in_gb = bytes as f64 / GB as f64;
    format!("{:.2} GB", size_in_gb)
  } else {
    let size_in_mb = bytes as f64 / MB as f64;
    format!("{:.2} MB", size_in_mb)
  }
}

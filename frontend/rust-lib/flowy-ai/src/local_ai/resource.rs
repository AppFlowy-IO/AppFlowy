use crate::local_ai::controller::LocalAISetting;
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use lib_infra::async_trait::async_trait;

use crate::entities::LackOfAIResourcePB;
use crate::notification::{
  chat_notification_builder, ChatNotification, APPFLOWY_AI_NOTIFICATION_KEY,
};
use af_local_ai::ollama_plugin::OllamaPluginConfig;
use af_plugin::core::path::{is_plugin_ready, ollama_plugin_path};
use flowy_ai_pub::user_service::AIUserService;
use lib_infra::util::{get_operating_system, OperatingSystem};
use reqwest::Client;
use serde::Deserialize;
use std::path::PathBuf;
use std::sync::Arc;
use std::time::Duration;
use tracing::{error, info, instrument, trace};

#[derive(Debug, Deserialize)]
struct TagsResponse {
  models: Vec<ModelEntry>,
}

#[derive(Debug, Deserialize)]
struct ModelEntry {
  name: String,
}

#[async_trait]
pub trait LLMResourceService: Send + Sync + 'static {
  /// Get local ai configuration from remote server
  fn store_setting(&self, setting: LocalAISetting) -> Result<(), anyhow::Error>;
  fn retrieve_setting(&self) -> Option<LocalAISetting>;
}

const LLM_MODEL_DIR: &str = "models";

#[derive(Debug, Clone)]
#[allow(dead_code)]
pub enum WatchDiskEvent {
  Create,
  Remove,
}

#[derive(Debug, Clone)]
pub enum PendingResource {
  PluginExecutableNotReady,
  OllamaServerNotReady,
  MissingModel(String),
}

pub struct LocalAIResourceController {
  user_service: Arc<dyn AIUserService>,
  resource_service: Arc<dyn LLMResourceService>,
}

impl LocalAIResourceController {
  pub fn new(
    user_service: Arc<dyn AIUserService>,
    resource_service: impl LLMResourceService,
  ) -> Self {
    Self {
      user_service,
      resource_service: Arc::new(resource_service),
    }
  }

  /// Returns true when all resources are downloaded and ready to use.
  pub async fn is_resource_ready(&self) -> bool {
    let sys = get_operating_system();
    if !sys.is_desktop() {
      return false;
    }

    self
      .calculate_pending_resources()
      .await
      .is_ok_and(|r| r.is_none())
  }

  /// Retrieves model information and updates the current model settings.
  pub fn get_llm_setting(&self) -> LocalAISetting {
    self.resource_service.retrieve_setting().unwrap_or_default()
  }

  #[instrument(level = "info", skip_all, err)]
  pub async fn set_llm_setting(&self, setting: LocalAISetting) -> FlowyResult<()> {
    self.resource_service.store_setting(setting)?;
    if let Some(resource) = self.calculate_pending_resources().await? {
      let resource = LackOfAIResourcePB::from(resource);
      chat_notification_builder(
        APPFLOWY_AI_NOTIFICATION_KEY,
        ChatNotification::LocalAIResourceUpdated,
      )
      .payload(resource.clone())
      .send();
      return Err(FlowyError::local_ai().with_context(format!("{:?}", resource)));
    }
    Ok(())
  }

  pub async fn get_lack_of_resource(&self) -> Option<LackOfAIResourcePB> {
    self
      .calculate_pending_resources()
      .await
      .ok()?
      .map(Into::into)
  }

  pub async fn calculate_pending_resources(&self) -> FlowyResult<Option<PendingResource>> {
    let app_path = ollama_plugin_path();
    if !is_plugin_ready() {
      trace!("[LLM Resource] offline app not found: {:?}", app_path);
      return Ok(Some(PendingResource::PluginExecutableNotReady));
    }

    let setting = self.get_llm_setting();
    let client = Client::builder().timeout(Duration::from_secs(5)).build()?;
    match client.get(&setting.ollama_server_url).send().await {
      Ok(resp) if resp.status().is_success() => {
        info!(
          "[LLM Resource] Ollama server is running at {}",
          setting.ollama_server_url
        );
      },
      _ => {
        info!(
          "[LLM Resource] Ollama server is not responding at {}",
          setting.ollama_server_url
        );
        return Ok(Some(PendingResource::OllamaServerNotReady));
      },
    }

    let required_models = vec![setting.chat_model_name, setting.embedding_model_name];

    // Query the /api/tags endpoint to get a structured list of locally available models.
    let tags_url = format!("{}/api/tags", setting.ollama_server_url);

    match client.get(&tags_url).send().await {
      Ok(resp) if resp.status().is_success() => {
        let tags: TagsResponse = resp.json().await.inspect_err(|e| {
          log::error!("[LLM Resource] Failed to parse /api/tags JSON response: {e:?}")
        })?;
        // Check if each of our required models exists in the list of available models
        trace!("[LLM Resource] ollama available models: {:?}", tags.models);
        for required in &required_models {
          if !tags
            .models
            .iter()
            .any(|m| m.name == *required || m.name == format!("{}:latest", required))
          {
            log::trace!(
              "[LLM Resource] required model '{}' not found in API response",
              required
            );
            return Ok(Some(PendingResource::MissingModel(required.clone())));
          }
        }
      },
      _ => {
        error!(
          "[LLM Resource] Failed to fetch models from {} (GET /api/tags)",
          setting.ollama_server_url
        );
        return Ok(Some(PendingResource::OllamaServerNotReady));
      },
    }

    Ok(None)
  }

  #[instrument(level = "info", skip_all)]
  pub async fn get_plugin_config(&self, rag_enabled: bool) -> FlowyResult<OllamaPluginConfig> {
    if !self.is_resource_ready().await {
      return Err(FlowyError::new(
        ErrorCode::AppFlowyLAINotReady,
        "AppFlowyLAI not found",
      ));
    }

    let llm_setting = self.get_llm_setting();
    let bin_path = match get_operating_system() {
      OperatingSystem::MacOS | OperatingSystem::Windows | OperatingSystem::Linux => {
        ollama_plugin_path()
      },
      _ => {
        return Err(
          FlowyError::local_ai_unavailable()
            .with_context("Local AI not available on current platform"),
        );
      },
    };

    let mut config = OllamaPluginConfig::new(
      bin_path,
      "af_ollama_plugin".to_string(),
      llm_setting.chat_model_name.clone(),
      llm_setting.embedding_model_name.clone(),
      Some(llm_setting.ollama_server_url.clone()),
    )?;

    //config = config.with_log_level("debug".to_string());

    if rag_enabled {
      let resource_dir = self.resource_dir()?;
      let persist_directory = resource_dir.join("vectorstore");
      if !persist_directory.exists() {
        std::fs::create_dir_all(&persist_directory)?;
      }
      config.set_rag_enabled(&persist_directory)?;
    }

    if cfg!(debug_assertions) {
      config = config.with_verbose(true);
    }
    trace!("[AI Chat] config: {:?}", config);
    Ok(config)
  }

  pub(crate) fn user_model_folder(&self) -> FlowyResult<PathBuf> {
    self.resource_dir().map(|dir| dir.join(LLM_MODEL_DIR))
  }

  pub(crate) fn resource_dir(&self) -> FlowyResult<PathBuf> {
    let user_data_dir = self.user_service.application_root_dir()?;
    Ok(user_data_dir.join("ai"))
  }
}

#[allow(dead_code)]
fn bytes_to_readable_format(bytes: u64) -> String {
  const BYTES_IN_GIGABYTE: u64 = 1024 * 1024 * 1024;
  const BYTES_IN_MEGABYTE: u64 = 1024 * 1024;

  if bytes >= BYTES_IN_GIGABYTE {
    let gigabytes = (bytes as f64) / (BYTES_IN_GIGABYTE as f64);
    format!("{:.1} GB", gigabytes)
  } else {
    let megabytes = (bytes as f64) / (BYTES_IN_MEGABYTE as f64);
    format!("{:.2} MB", megabytes)
  }
}

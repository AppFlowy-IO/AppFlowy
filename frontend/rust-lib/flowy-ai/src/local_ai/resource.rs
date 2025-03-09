use crate::ai_manager::AIUserService;
use crate::local_ai::controller::LocalAISetting;
use flowy_ai_pub::cloud::LocalAIConfig;
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use lib_infra::async_trait::async_trait;

use crate::entities::LackOfAIResourcePB;
use crate::local_ai::watch::ollama_plugin_path;
#[cfg(target_os = "macos")]
use crate::local_ai::watch::{watch_offline_app, WatchContext};
use crate::notification::{
  chat_notification_builder, ChatNotification, APPFLOWY_AI_NOTIFICATION_KEY,
};
use appflowy_local_ai::ollama_plugin::OllamaPluginConfig;
use lib_infra::util::{get_operating_system, OperatingSystem};
use reqwest::Client;
use std::path::PathBuf;
use std::sync::Arc;
use std::time::Duration;
use tracing::{error, info, instrument, trace};

#[async_trait]
pub trait LLMResourceService: Send + Sync + 'static {
  /// Get local ai configuration from remote server
  async fn fetch_local_ai_config(&self) -> Result<LocalAIConfig, anyhow::Error>;
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

pub enum PendingResource {
  LocalAIAppNotDownloaded,
  OllamaServerNotFound,
  OllamaNotInstalled,
  MissingModel(String),
}

impl PendingResource {
  pub fn desc(self) -> String {
    match self {
      PendingResource::LocalAIAppNotDownloaded => "Local AI app not downloaded".to_string(),
      PendingResource::OllamaServerNotFound => "Ollama server not ready".to_string(),
      PendingResource::OllamaNotInstalled => "Ollama not installed".to_string(),
      PendingResource::MissingModel(model) => format!("Missing model: {}", model),
    }
  }
}

pub struct LocalAIResourceController {
  user_service: Arc<dyn AIUserService>,
  resource_service: Arc<dyn LLMResourceService>,
  resource_notify: tokio::sync::broadcast::Sender<()>,
  #[cfg(target_os = "macos")]
  #[allow(dead_code)]
  app_disk_watch: Option<WatchContext>,
  app_state_sender: tokio::sync::broadcast::Sender<WatchDiskEvent>,
}

impl LocalAIResourceController {
  pub fn new(
    user_service: Arc<dyn AIUserService>,
    resource_service: impl LLMResourceService,
  ) -> Self {
    let (resource_notify, _) = tokio::sync::broadcast::channel(1);
    let (app_state_sender, _) = tokio::sync::broadcast::channel(1);
    #[cfg(target_os = "macos")]
    let mut offline_app_disk_watch: Option<WatchContext> = None;

    #[cfg(target_os = "macos")]
    {
      match watch_offline_app() {
        Ok((new_watcher, mut rx)) => {
          let sender = app_state_sender.clone();
          tokio::spawn(async move {
            while let Some(event) = rx.recv().await {
              if let Err(err) = sender.send(event) {
                error!("[LLM Resource] Failed to send offline app state: {:?}", err);
              }
            }
          });
          offline_app_disk_watch = Some(new_watcher);
        },
        Err(err) => {
          error!("[LLM Resource] Failed to watch offline app path: {:?}", err);
        },
      }
    }

    Self {
      user_service,
      resource_service: Arc::new(resource_service),
      #[cfg(target_os = "macos")]
      app_disk_watch: offline_app_disk_watch,
      app_state_sender,
      resource_notify,
    }
  }

  pub fn subscribe_resource_notify(&self) -> tokio::sync::broadcast::Receiver<()> {
    self.resource_notify.subscribe()
  }

  pub fn subscribe_app_state(&self) -> tokio::sync::broadcast::Receiver<WatchDiskEvent> {
    self.app_state_sender.subscribe()
  }

  /// Returns true when all resources are downloaded and ready to use.
  pub async fn is_resource_ready(&self) -> bool {
    let sys = get_operating_system();
    if !sys.is_desktop() {
      return false;
    }

    match self.calculate_pending_resources().await {
      Ok(res) => res.is_empty(),
      Err(_) => false,
    }
  }

  pub fn is_app_downloaded(&self) -> bool {
    ollama_plugin_path().exists()
  }

  pub async fn get_plugin_download_link(&self) -> FlowyResult<String> {
    let ai_config = self.get_local_ai_configuration().await?;
    Ok(ai_config.plugin.url)
  }

  /// Retrieves model information and updates the current model settings.
  pub fn get_llm_setting(&self) -> LocalAISetting {
    self.resource_service.retrieve_setting().unwrap_or_default()
  }

  #[instrument(level = "info", skip_all, err)]
  pub async fn set_llm_setting(&self, setting: LocalAISetting) -> FlowyResult<()> {
    self.resource_service.store_setting(setting)?;
    let mut resources = self.calculate_pending_resources().await?;
    if let Some(resource) = resources.pop() {
      chat_notification_builder(
        APPFLOWY_AI_NOTIFICATION_KEY,
        ChatNotification::LocalAIResourceUpdated,
      )
      .payload(LackOfAIResourcePB {
        resource_desc: resource.desc(),
      })
      .send();
    }
    Ok(())
  }

  pub async fn get_lack_of_resource(&self) -> Option<String> {
    let mut resources = self.calculate_pending_resources().await.ok()?;
    resources.pop().map(|r| r.desc())
  }

  /// Returns true when all resources are downloaded and ready to use.
  pub async fn calculate_pending_resources(&self) -> FlowyResult<Vec<PendingResource>> {
    let mut resources = vec![];
    let app_path = ollama_plugin_path();
    if !app_path.exists() {
      trace!("[LLM Resource] offline app not found: {:?}", app_path);
      resources.push(PendingResource::LocalAIAppNotDownloaded);
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
        resources.push(PendingResource::OllamaServerNotFound);
        return Ok(resources);
      },
    }

    let required_models = vec![
      setting.chat_model_name,
      setting.embedding_model_name,
      // Add any additional required models here.
    ];
    match tokio::process::Command::new("ollama")
      .arg("list")
      .output()
      .await
    {
      Ok(output) if output.status.success() => {
        let stdout = String::from_utf8_lossy(&output.stdout);
        for model in &required_models {
          if !stdout.contains(model.as_str()) {
            log::trace!(
              "[LLM Resource] required model '{}' not found in ollama list",
              model
            );
            resources.push(PendingResource::MissingModel(model.clone()));
            return Ok(resources);
          }
        }
      },
      Ok(output) => {
        error!(
          "[LLM Resource] 'ollama list' command failed with status: {:?}",
          output.status
        );
        resources.push(PendingResource::OllamaNotInstalled);
      },
      Err(e) => {
        error!("[LLM Resource] failed to execute 'ollama list': {:?}", e);
        resources.push(PendingResource::OllamaNotInstalled);
      },
    }

    Ok(resources)
  }

  #[instrument(level = "info", skip_all)]
  pub async fn get_plugin_config(&self, rag_enabled: bool) -> FlowyResult<OllamaPluginConfig> {
    if !self.is_resource_ready().await {
      return Err(FlowyError::local_ai().with_context("Local AI resources are not ready"));
    }

    let llm_setting = self.get_llm_setting();
    let bin_path = match get_operating_system() {
      OperatingSystem::MacOS | OperatingSystem::Windows => {
        let path = ollama_plugin_path();
        if !path.exists() {
          return Err(FlowyError::new(
            ErrorCode::AIOfflineNotInstalled,
            format!("AppFlowy Offline not installed at path: {:?}", path),
          ));
        }
        path
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
      llm_setting.chat_model_name.clone(),
      llm_setting.embedding_model_name.clone(),
      Some(llm_setting.ollama_server_url.clone()),
    )?;

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

  /// Fetches the local AI configuration from the resource service.
  async fn get_local_ai_configuration(&self) -> FlowyResult<LocalAIConfig> {
    self
      .resource_service
      .fetch_local_ai_config()
      .await
      .map_err(|err| {
        error!("[LLM Resource] Failed to fetch local ai config: {:?}", err);
        FlowyError::local_ai()
          .with_context("Can't retrieve model info. Please try again later".to_string())
      })
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

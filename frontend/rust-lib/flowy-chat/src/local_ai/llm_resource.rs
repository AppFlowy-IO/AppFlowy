use crate::chat_manager::ChatUserService;
use crate::entities::{LocalModelResourcePB, PendingResourcePB};
use crate::local_ai::local_llm_chat::{LLMModelInfo, LLMSetting};
use crate::local_ai::model_request::download_model;

use appflowy_local_ai::chat_plugin::AIPluginConfig;
use flowy_chat_pub::cloud::{LLMModel, LocalAIConfig, ModelInfo};
use flowy_error::{FlowyError, FlowyResult};
use futures::Sink;
use futures_util::SinkExt;
use lib_infra::async_trait::async_trait;
use parking_lot::RwLock;

use appflowy_local_ai::plugin_request::download_plugin;
use std::path::PathBuf;
use std::sync::Arc;
use tokio::fs::{self};
use tokio_util::sync::CancellationToken;
use tracing::{debug, error, info, instrument, trace};
use zip_extensions::zip_extract;

#[async_trait]
pub trait LLMResourceService: Send + Sync + 'static {
  async fn get_local_ai_config(&self) -> Result<LocalAIConfig, anyhow::Error>;
  fn store(&self, setting: LLMSetting) -> Result<(), anyhow::Error>;
  fn retrieve(&self) -> Option<LLMSetting>;
}

const PLUGIN_DIR: &str = "plugin";
const LLM_MODEL_DIR: &str = "models";
const DOWNLOAD_FINISH: &str = "finish";

pub enum PendingResource {
  PluginRes,
  ModelInfoRes(Vec<ModelInfo>),
}
#[derive(Clone)]
pub struct DownloadTask {
  cancel_token: CancellationToken,
  tx: tokio::sync::broadcast::Sender<String>,
}
impl DownloadTask {
  pub fn new() -> Self {
    let (tx, _) = tokio::sync::broadcast::channel(5);
    let cancel_token = CancellationToken::new();
    Self { cancel_token, tx }
  }

  pub fn cancel(&self) {
    self.cancel_token.cancel();
  }
}

pub struct LLMResourceController {
  user_service: Arc<dyn ChatUserService>,
  resource_service: Arc<dyn LLMResourceService>,
  llm_setting: RwLock<Option<LLMSetting>>,
  // The ai_config will be set when user try to get latest local ai config from server
  ai_config: RwLock<Option<LocalAIConfig>>,
  download_task: Arc<RwLock<Option<DownloadTask>>>,
  resource_notify: tokio::sync::mpsc::Sender<()>,
}

impl LLMResourceController {
  pub fn new(
    user_service: Arc<dyn ChatUserService>,
    resource_service: impl LLMResourceService,
    resource_notify: tokio::sync::mpsc::Sender<()>,
  ) -> Self {
    let llm_setting = RwLock::new(resource_service.retrieve());
    Self {
      user_service,
      resource_service: Arc::new(resource_service),
      llm_setting,
      ai_config: Default::default(),
      download_task: Default::default(),
      resource_notify,
    }
  }

  /// Returns true when all resources are downloaded and ready to use.
  pub fn is_resource_ready(&self) -> bool {
    match self.calculate_pending_resources() {
      Ok(res) => res.is_empty(),
      Err(_) => false,
    }
  }

  /// Retrieves model information and updates the current model settings.
  #[instrument(level = "debug", skip_all, err)]
  pub async fn refresh_llm_resource(&self) -> FlowyResult<LLMModelInfo> {
    let ai_config = self.fetch_ai_config().await?;
    if ai_config.models.is_empty() {
      return Err(FlowyError::local_ai().with_context("No model found"));
    }

    *self.ai_config.write() = Some(ai_config.clone());
    let selected_model = self.select_model(&ai_config)?;

    let llm_setting = LLMSetting {
      plugin: ai_config.plugin.clone(),
      llm_model: selected_model.clone(),
    };
    self.llm_setting.write().replace(llm_setting.clone());
    self.resource_service.store(llm_setting)?;

    Ok(LLMModelInfo {
      selected_model,
      models: ai_config.models,
    })
  }

  #[instrument(level = "info", skip_all, err)]
  pub fn use_local_llm(&self, llm_id: i64) -> FlowyResult<LocalModelResourcePB> {
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

    trace!("[LLM Resource] Selected AI setting: {:?}", llm_setting);
    *self.llm_setting.write() = Some(llm_setting.clone());
    self.resource_service.store(llm_setting)?;
    self.get_local_llm_state()
  }

  pub fn get_local_llm_state(&self) -> FlowyResult<LocalModelResourcePB> {
    let state = self
      .check_resource()
      .ok_or_else(|| FlowyError::local_ai().with_context("No local ai config found"))?;
    Ok(state)
  }

  #[instrument(level = "debug", skip_all)]
  fn check_resource(&self) -> Option<LocalModelResourcePB> {
    trace!("[LLM Resource] Checking local ai resources");

    let pending_resources = self.calculate_pending_resources().ok()?;
    let is_ready = pending_resources.is_empty();
    let is_downloading = self.download_task.read().is_some();
    let pending_resources: Vec<_> = pending_resources
      .into_iter()
      .flat_map(|res| match res {
        PendingResource::PluginRes => vec![PendingResourcePB {
          name: "AppFlowy Plugin".to_string(),
          file_size: 0,
          requirements: "".to_string(),
        }],
        PendingResource::ModelInfoRes(model_infos) => model_infos
          .into_iter()
          .map(|model_info| PendingResourcePB {
            name: model_info.name,
            file_size: model_info.file_size,
            requirements: model_info.requirements,
          })
          .collect::<Vec<_>>(),
      })
      .collect();

    let resource = LocalModelResourcePB {
      is_ready,
      pending_resources,
      is_downloading,
    };

    debug!("[LLM Resource] Local AI resources state: {:?}", resource);
    Some(resource)
  }

  /// Returns true when all resources are downloaded and ready to use.
  pub fn calculate_pending_resources(&self) -> FlowyResult<Vec<PendingResource>> {
    match self.llm_setting.read().as_ref() {
      None => Err(FlowyError::local_ai().with_context("Can't find any llm config")),
      Some(llm_setting) => {
        let mut resources = vec![];
        let plugin_path = self.plugin_path(&llm_setting.plugin.etag)?;

        if !plugin_path.exists() {
          trace!("[LLM Resource] Plugin file not found: {:?}", plugin_path);
          resources.push(PendingResource::PluginRes);
        }

        let chat_model = self.model_path(&llm_setting.llm_model.chat_model.file_name)?;
        if !chat_model.exists() {
          resources.push(PendingResource::ModelInfoRes(vec![llm_setting
            .llm_model
            .chat_model
            .clone()]));
        }

        let embedding_model = self.model_path(&llm_setting.llm_model.embedding_model.file_name)?;
        if !embedding_model.exists() {
          resources.push(PendingResource::ModelInfoRes(vec![llm_setting
            .llm_model
            .embedding_model
            .clone()]));
        }

        Ok(resources)
      },
    }
  }

  #[instrument(level = "info", skip_all, err)]
  pub async fn start_downloading<T>(&self, mut progress_sink: T) -> FlowyResult<String>
  where
    T: Sink<String, Error = anyhow::Error> + Unpin + Sync + Send + 'static,
  {
    let task_id = uuid::Uuid::new_v4().to_string();
    let weak_download_task = Arc::downgrade(&self.download_task);
    let resource_notify = self.resource_notify.clone();
    // notify download progress to client.
    let progress_notify = |mut rx: tokio::sync::broadcast::Receiver<String>| {
      tokio::spawn(async move {
        while let Ok(value) = rx.recv().await {
          let is_finish = value == DOWNLOAD_FINISH;
          if let Err(err) = progress_sink.send(value).await {
            error!("Failed to send progress: {:?}", err);
            break;
          }

          if is_finish {
            info!("notify download finish, need to reload resources");
            let _ = resource_notify.send(()).await;
            if let Some(download_task) = weak_download_task.upgrade() {
              if let Some(task) = download_task.write().take() {
                task.cancel();
              }
            }
            break;
          }
        }
      });
    };

    // return immediately if download task already exists
    if let Some(download_task) = self.download_task.read().as_ref() {
      trace!(
        "Download task already exists, return the task id: {}",
        task_id
      );
      progress_notify(download_task.tx.subscribe());
      return Ok(task_id);
    }

    // If download task is not exists, create a new download task.
    info!("[LLM Resource] Start new download task");
    let llm_setting = self
      .llm_setting
      .read()
      .clone()
      .ok_or_else(|| FlowyError::local_ai().with_context("No local ai config found"))?;

    let download_task = DownloadTask::new();
    *self.download_task.write() = Some(download_task.clone());
    progress_notify(download_task.tx.subscribe());

    let plugin_dir = self.user_plugin_folder()?;
    if !plugin_dir.exists() {
      fs::create_dir_all(&plugin_dir).await.map_err(|err| {
        FlowyError::local_ai().with_context(format!("Failed to create plugin dir: {:?}", err))
      })?;
    }

    let model_dir = self.user_model_folder()?;
    if !model_dir.exists() {
      fs::create_dir_all(&model_dir).await.map_err(|err| {
        FlowyError::local_ai().with_context(format!("Failed to create model dir: {:?}", err))
      })?;
    }

    tokio::spawn(async move {
      let plugin_file_etag_dir = plugin_dir.join(&llm_setting.plugin.etag);
      // We use the ETag as the identifier for the plugin file. If a file with the given ETag
      // already exists, skip downloading it.
      if !plugin_file_etag_dir.exists() {
        let plugin_progress_tx = download_task.tx.clone();
        info!(
          "[LLM Resource] Downloading plugin: {:?}",
          llm_setting.plugin.etag
        );
        let file_name = format!("{}.zip", llm_setting.plugin.etag);
        let zip_plugin_file = download_plugin(
          &llm_setting.plugin.url,
          &plugin_dir,
          &file_name,
          Some(download_task.cancel_token.clone()),
          Some(Arc::new(move |downloaded, total_size| {
            let progress = (downloaded as f64 / total_size as f64).clamp(0.0, 1.0);
            let _ = plugin_progress_tx.send(format!("plugin:progress:{}", progress));
          })),
        )
        .await?;

        // unzip file
        info!(
          "[LLM Resource] unzip {:?} to {:?}",
          zip_plugin_file, plugin_file_etag_dir
        );
        zip_extract(&zip_plugin_file, &plugin_file_etag_dir)?;

        // delete zip file
        info!("[LLM Resource] Delete zip file: {:?}", file_name);
        if let Err(err) = fs::remove_file(&zip_plugin_file).await {
          error!("Failed to delete zip file: {:?}", err);
        }
      }

      // After download the plugin, start downloading models
      let chat_model_file = (
        model_dir.join(&llm_setting.llm_model.chat_model.file_name),
        llm_setting.llm_model.chat_model.file_name,
        llm_setting.llm_model.chat_model.name,
        llm_setting.llm_model.chat_model.download_url,
      );
      let embedding_model_file = (
        model_dir.join(&llm_setting.llm_model.embedding_model.file_name),
        llm_setting.llm_model.embedding_model.file_name,
        llm_setting.llm_model.embedding_model.name,
        llm_setting.llm_model.embedding_model.download_url,
      );
      for (file_path, file_name, model_name, url) in [chat_model_file, embedding_model_file] {
        if file_path.exists() {
          continue;
        }

        info!("[LLM Resource] Downloading model: {:?}", file_name);
        let plugin_progress_tx = download_task.tx.clone();
        let cloned_model_name = model_name.clone();
        let progress = Arc::new(move |downloaded, total_size| {
          let progress = (downloaded as f64 / total_size as f64).clamp(0.0, 1.0);
          let _ = plugin_progress_tx.send(format!("{}:progress:{}", cloned_model_name, progress));
        });
        match download_model(
          &url,
          &model_dir,
          &file_name,
          Some(progress),
          Some(download_task.cancel_token.clone()),
        )
        .await
        {
          Ok(_) => info!("[LLM Resource] Downloaded model: {:?}", file_name),
          Err(err) => {
            error!(
              "[LLM Resource] Failed to download model for given url: {:?}, error: {:?}",
              url, err
            );
            download_task
              .tx
              .send(format!("error:failed to download {}", model_name))?;
            continue;
          },
        }
      }
      info!("[LLM Resource] All resources downloaded");
      download_task.tx.send(DOWNLOAD_FINISH.to_string())?;
      Ok::<_, anyhow::Error>(())
    });

    Ok(task_id)
  }

  pub fn cancel_download(&self) -> FlowyResult<()> {
    if let Some(cancel_token) = self.download_task.write().take() {
      info!("[LLM Resource] Cancel download");
      cancel_token.cancel();
    }

    Ok(())
  }

  #[instrument(level = "debug", skip_all, err)]
  pub fn get_ai_plugin_config(&self) -> FlowyResult<AIPluginConfig> {
    if !self.is_resource_ready() {
      return Err(FlowyError::local_ai().with_context("Local AI resources are not ready"));
    }

    let llm_setting = self
      .llm_setting
      .read()
      .as_ref()
      .cloned()
      .ok_or_else(|| FlowyError::local_ai().with_context("No local llm setting found"))?;

    let model_dir = self.user_model_folder()?;
    let resource_dir = self.resource_dir()?;

    let bin_path = self
      .plugin_path(&llm_setting.plugin.etag)?
      .join(llm_setting.plugin.name);
    let chat_model_path = model_dir.join(&llm_setting.llm_model.chat_model.file_name);
    let embedding_model_path = model_dir.join(&llm_setting.llm_model.embedding_model.file_name);
    let mut config = AIPluginConfig::new(bin_path, chat_model_path)?;

    //
    let persist_directory = resource_dir.join("rag");
    if !persist_directory.exists() {
      std::fs::create_dir_all(&persist_directory)?;
    }

    // Enable RAG when the embedding model path is set
    config.set_rag_enabled(&embedding_model_path, &persist_directory)?;

    if cfg!(debug_assertions) {
      config = config.with_verbose(true);
    }
    Ok(config)
  }

  /// Fetches the local AI configuration from the resource service.
  async fn fetch_ai_config(&self) -> FlowyResult<LocalAIConfig> {
    self
      .resource_service
      .get_local_ai_config()
      .await
      .map_err(|err| {
        error!("[LLM Resource] Failed to fetch local ai config: {:?}", err);
        FlowyError::local_ai()
          .with_context("Can't retrieve model info. Please try again later".to_string())
      })
  }

  /// Selects the appropriate model based on the current settings or defaults to the first model.
  fn select_model(&self, ai_config: &LocalAIConfig) -> FlowyResult<LLMModel> {
    let selected_model = match self.llm_setting.read().as_ref() {
      None => ai_config.models[0].clone(),
      Some(llm_setting) => {
        match ai_config
          .models
          .iter()
          .find(|model| model.llm_id == llm_setting.llm_model.llm_id)
        {
          None => ai_config.models[0].clone(),
          Some(llm_model) => {
            if llm_model != &llm_setting.llm_model {
              info!(
                "[LLM Resource] existing model is different from remote, replace with remote model"
              );
            }
            llm_model.clone()
          },
        }
      },
    };
    Ok(selected_model)
  }

  fn user_plugin_folder(&self) -> FlowyResult<PathBuf> {
    self.resource_dir().map(|dir| dir.join(PLUGIN_DIR))
  }

  fn user_model_folder(&self) -> FlowyResult<PathBuf> {
    self.resource_dir().map(|dir| dir.join(LLM_MODEL_DIR))
  }

  fn plugin_path(&self, etag: &str) -> FlowyResult<PathBuf> {
    self.user_plugin_folder().map(|dir| dir.join(etag))
  }

  fn model_path(&self, model_file_name: &str) -> FlowyResult<PathBuf> {
    self
      .user_model_folder()
      .map(|dir| dir.join(model_file_name))
  }

  fn resource_dir(&self) -> FlowyResult<PathBuf> {
    let user_data_dir = self.user_service.user_data_dir()?;
    Ok(user_data_dir.join("llm"))
  }
}

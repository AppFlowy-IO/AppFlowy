use crate::entities::LocalAIPB;
use crate::local_ai::resource::{LLMResourceService, LocalAIResourceController};
use crate::notification::{
  chat_notification_builder, ChatNotification, APPFLOWY_AI_NOTIFICATION_KEY,
};
use anyhow::Error;
use flowy_error::{FlowyError, FlowyResult};
use flowy_sqlite::kv::KVStorePreferences;
use futures::Sink;
use lib_infra::async_trait::async_trait;
use std::collections::HashMap;

use crate::local_ai::chat::LLMChatController;
use crate::stream_message::StreamMessage;
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
use tracing::{debug, error, info, instrument};
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
  llm_controller: LLMChatController,
  resource: Arc<LocalAIResourceController>,
  current_chat_id: ArcSwapOption<Uuid>,
  store_preferences: Weak<KVStorePreferences>,
  user_service: Arc<dyn AIUserService>,
  pub(crate) ollama: ArcSwapOption<Ollama>,
}

impl Deref for LocalAIController {
  type Target = LLMChatController;

  fn deref(&self) -> &Self::Target {
    &self.llm_controller
  }
}

impl LocalAIController {
  pub fn new(
    store_preferences: Weak<KVStorePreferences>,
    user_service: Arc<dyn AIUserService>,
  ) -> Self {
    debug!(
      "[Local AI] init local ai controller, thread: {:?}",
      std::thread::current().id()
    );

    // Create the core plugin and resource controller
    let res_impl = LLMResourceServiceImpl {
      store_preferences: store_preferences.clone(),
    };
    let local_ai_resource = Arc::new(LocalAIResourceController::new(
      user_service.clone(),
      res_impl,
    ));

    let ollama = ArcSwapOption::default();
    let llm_controller = LLMChatController::new(Arc::downgrade(&user_service));
    Self {
      llm_controller,
      resource: local_ai_resource,
      current_chat_id: ArcSwapOption::default(),
      store_preferences,
      user_service,
      ollama,
    }
  }

  pub async fn reload_ollama_client(&self, workspace_id: &str) {
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
    match Ollama::try_new(&setting.ollama_server_url).map(Arc::new) {
      Ok(new_ollama) => {
        #[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
        {
          info!("[Local AI] reload ollama client successfully");
          let shared = crate::embeddings::context::EmbedContext::shared();
          shared.set_ollama(Some(new_ollama.clone()));
          if let Some(vc) = shared.get_vector_db() {
            self
              .llm_controller
              .initialize(Arc::downgrade(&new_ollama), Arc::downgrade(&vc))
              .await;
          } else {
            error!("[Local AI] vector db is not initialized");
          }
        }
        self.ollama.store(Some(new_ollama.clone()));
      },
      Err(err) => error!(
        "[Local AI] failed to create ollama client: {:?}, thread: {:?}",
        err,
        std::thread::current().id()
      ),
    }
  }

  fn upgrade_store_preferences(&self) -> FlowyResult<Arc<KVStorePreferences>> {
    self
      .store_preferences
      .upgrade()
      .ok_or_else(|| FlowyError::internal().with_context("Store preferences is dropped"))
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
    if !get_operating_system().is_desktop() {
      return false;
    }

    let key = local_ai_enabled_key(workspace_id);
    match self.upgrade_store_preferences() {
      Ok(store) => store.get_bool(&key).unwrap_or(false),
      Err(_) => false,
    }
  }

  pub fn get_local_chat_model(&self) -> Option<String> {
    if !self.is_enabled() {
      return None;
    }
    Some(self.resource.get_llm_setting().chat_model_name)
  }

  pub async fn open_chat(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    model: &str,
  ) -> FlowyResult<()> {
    if !self.is_enabled() {
      return Ok(());
    }

    // Only keep one chat open at a time. Since loading multiple models at the same time will cause
    // memory issues.
    if let Some(current_chat_id) = self.current_chat_id.load().as_ref() {
      debug!("[Local AI] close previous chat: {}", current_chat_id);
      self.close_chat(current_chat_id);
    }

    self.current_chat_id.store(Some(Arc::new(*chat_id)));
    self
      .llm_controller
      .open_chat(workspace_id, chat_id, model)
      .await?;
    Ok(())
  }

  pub fn close_chat(&self, chat_id: &Uuid) {
    info!("[Local AI] notify close chat: {}", chat_id);
    self.llm_controller.close_chat(chat_id);
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
    let enabled = self.is_enabled();
    if !enabled {
      return LocalAIPB {
        enabled,
        lack_of_resource: None,
        is_ready: self.is_ready().await,
      };
    }
    let lack_of_resource = self.resource.get_lack_of_resource().await;
    LocalAIPB {
      enabled,
      lack_of_resource,
      is_ready: self.is_ready().await,
    }
  }

  #[instrument(level = "debug", skip_all)]
  pub async fn restart_plugin(&self) {
    if let Err(err) = check_local_ai_resources(&self.resource, &self.llm_controller).await {
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
      .llm_controller
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
      if let Err(err) = check_local_ai_resources(&self.resource, &self.llm_controller).await {
        error!("[Local AI] failed to initialize local ai: {:?}", err);
      }
    } else {
      chat_notification_builder(
        APPFLOWY_AI_NOTIFICATION_KEY,
        ChatNotification::UpdateLocalAIState,
      )
      .payload(LocalAIPB {
        enabled,
        lack_of_resource: None,
        is_ready: self.is_ready().await,
      })
      .send();
    }
    Ok(())
  }
}

#[instrument(level = "debug", skip_all, err)]
async fn check_local_ai_resources(
  llm_resource: &Arc<LocalAIResourceController>,
  llm_controller: &LLMChatController,
) -> FlowyResult<()> {
  let lack_of_resource = llm_resource.get_lack_of_resource().await;

  chat_notification_builder(
    APPFLOWY_AI_NOTIFICATION_KEY,
    ChatNotification::UpdateLocalAIState,
  )
  .payload(LocalAIPB {
    enabled: true,
    lack_of_resource: lack_of_resource.clone(),
    is_ready: llm_controller.is_ready().await,
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

use crate::chat_manager::ChatUserService;
use crate::entities::{
  ChatStatePB, LocalModelResourcePB, ModelTypePB, PluginStatePB, RunningStatePB,
};
use crate::local_ai::llm_resource::{LLMResourceController, LLMResourceService};
use crate::notification::{send_notification, ChatNotification};
use anyhow::Error;
use appflowy_local_ai::chat_plugin::{AIPluginConfig, LocalChatLLMChat};
use appflowy_plugin::manager::PluginManager;
use appflowy_plugin::util::is_apple_silicon;
use flowy_chat_pub::cloud::{AppFlowyAIPlugin, ChatCloudService, LLMModel, LocalAIConfig};
use flowy_error::FlowyResult;
use flowy_sqlite::kv::KVStorePreferences;
use futures::Sink;
use lib_infra::async_trait::async_trait;

use serde::{Deserialize, Serialize};
use std::ops::Deref;

use parking_lot::Mutex;
use std::sync::Arc;
use tokio_stream::StreamExt;
use tracing::{debug, error, info, trace};

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct LLMSetting {
  pub plugin: AppFlowyAIPlugin,
  pub llm_model: LLMModel,
}

pub struct LLMModelInfo {
  pub selected_model: LLMModel,
  pub models: Vec<LLMModel>,
}

const LOCAL_AI_SETTING_KEY: &str = "local_ai_setting";
pub struct LocalAIController {
  llm_chat: Arc<LocalChatLLMChat>,
  llm_res: Arc<LLMResourceController>,
  current_chat_id: Mutex<Option<String>>,
}

impl Deref for LocalAIController {
  type Target = Arc<LocalChatLLMChat>;

  fn deref(&self) -> &Self::Target {
    &self.llm_chat
  }
}

impl LocalAIController {
  pub fn new(
    plugin_manager: Arc<PluginManager>,
    store_preferences: Arc<KVStorePreferences>,
    user_service: Arc<dyn ChatUserService>,
    cloud_service: Arc<dyn ChatCloudService>,
  ) -> Self {
    let llm_chat = Arc::new(LocalChatLLMChat::new(plugin_manager));
    let mut rx = llm_chat.subscribe_running_state();
    tokio::spawn(async move {
      while let Some(state) = rx.next().await {
        info!("[AI Plugin] state: {:?}", state);
        let new_state = RunningStatePB::from(state);
        send_notification(
          "appflowy_chat_plugin",
          ChatNotification::UpdateChatPluginState,
        )
        .payload(PluginStatePB { state: new_state })
        .send();
      }
    });

    let res_impl = LLMResourceServiceImpl {
      user_service: user_service.clone(),
      cloud_service,
      store_preferences,
    };

    let (tx, mut rx) = tokio::sync::mpsc::channel(1);
    let llm_res = Arc::new(LLMResourceController::new(user_service, res_impl, tx));

    let cloned_llm_chat = llm_chat.clone();
    let cloned_llm_res = llm_res.clone();
    tokio::spawn(async move {
      while rx.recv().await.is_some() {
        if let Ok(chat_config) = cloned_llm_res.get_ai_plugin_config() {
          if let Err(err) = initialize_chat_plugin(&cloned_llm_chat, chat_config) {
            error!("[AI Plugin] failed to setup plugin: {:?}", err);
          }
        }
      }
    });

    Self {
      llm_chat,
      llm_res,
      current_chat_id: Default::default(),
    }
  }
  pub async fn refresh(&self) -> FlowyResult<LLMModelInfo> {
    self.llm_res.refresh_llm_resource().await
  }

  pub fn initialize(&self) -> FlowyResult<()> {
    let chat_config = self.llm_res.get_ai_plugin_config()?;
    let llm_chat = self.llm_chat.clone();
    initialize_chat_plugin(&llm_chat, chat_config)?;
    Ok(())
  }

  /// Returns true if the local AI is enabled and ready to use.
  pub fn is_ready(&self) -> bool {
    self.llm_res.is_resource_ready()
  }

  pub fn open_chat(&self, chat_id: &str) {
    if !self.is_ready() {
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
    let weak_ctrl = Arc::downgrade(&self.llm_chat);
    tokio::spawn(async move {
      if let Some(ctrl) = weak_ctrl.upgrade() {
        if let Err(err) = ctrl.create_chat(&chat_id).await {
          error!("[AI Plugin] failed to open chat: {:?}", err);
        }
      }
    });
  }

  pub fn close_chat(&self, chat_id: &str) {
    let weak_ctrl = Arc::downgrade(&self.llm_chat);
    let chat_id = chat_id.to_string();
    tokio::spawn(async move {
      if let Some(ctrl) = weak_ctrl.upgrade() {
        if let Err(err) = ctrl.close_chat(&chat_id).await {
          error!("[AI Plugin] failed to close chat: {:?}", err);
        }
      }
    });
  }

  pub async fn use_local_llm(&self, llm_id: i64) -> FlowyResult<LocalModelResourcePB> {
    let llm_chat = self.llm_chat.clone();
    match llm_chat.destroy_chat_plugin().await {
      Ok(_) => info!("[AI Plugin] destroy plugin successfully"),
      Err(err) => error!("[AI Plugin] failed to destroy plugin: {:?}", err),
    }
    let state = self.llm_res.use_local_llm(llm_id)?;
    // Re-initialize the plugin if the setting is updated and ready to use
    if self.llm_res.is_resource_ready() {
      self.initialize()?;
    }
    Ok(state)
  }

  pub async fn get_local_llm_state(&self) -> FlowyResult<LocalModelResourcePB> {
    self.llm_res.get_local_llm_state()
  }

  pub async fn start_downloading<T>(&self, progress_sink: T) -> FlowyResult<String>
  where
    T: Sink<String, Error = anyhow::Error> + Unpin + Sync + Send + 'static,
  {
    let task_id = self.llm_res.start_downloading(progress_sink).await?;
    Ok(task_id)
  }

  pub fn cancel_download(&self) -> FlowyResult<()> {
    self.llm_res.cancel_download()?;
    Ok(())
  }

  pub fn get_plugin_state(&self) -> PluginStatePB {
    let state = self.llm_chat.get_plugin_running_state();
    PluginStatePB {
      state: RunningStatePB::from(state),
    }
  }

  pub fn restart(&self) {
    if let Ok(chat_config) = self.llm_res.get_ai_plugin_config() {
      if let Err(err) = initialize_chat_plugin(&self.llm_chat, chat_config) {
        error!("[AI Plugin] failed to setup plugin: {:?}", err);
      }
    }
  }
}

fn initialize_chat_plugin(
  llm_chat: &Arc<LocalChatLLMChat>,
  mut chat_config: AIPluginConfig,
) -> FlowyResult<()> {
  let llm_chat = llm_chat.clone();
  tokio::spawn(async move {
    trace!("[AI Plugin] config: {:?}", chat_config);
    if is_apple_silicon().await.unwrap_or(false) {
      chat_config = chat_config.with_device("gpu");
    }
    match llm_chat.init_chat_plugin(chat_config).await {
      Ok(_) => {
        send_notification(
          "appflowy_chat_plugin",
          ChatNotification::UpdateChatPluginState,
        )
        .payload(ChatStatePB {
          model_type: ModelTypePB::LocalAI,
          available: true,
        });
      },
      Err(err) => {
        send_notification(
          "appflowy_chat_plugin",
          ChatNotification::UpdateChatPluginState,
        )
        .payload(ChatStatePB {
          model_type: ModelTypePB::LocalAI,
          available: false,
        });
        error!("[AI Plugin] failed to setup plugin: {:?}", err);
      },
    }
  });
  Ok(())
}

pub struct LLMResourceServiceImpl {
  user_service: Arc<dyn ChatUserService>,
  cloud_service: Arc<dyn ChatCloudService>,
  store_preferences: Arc<KVStorePreferences>,
}
#[async_trait]
impl LLMResourceService for LLMResourceServiceImpl {
  async fn get_local_ai_config(&self) -> Result<LocalAIConfig, anyhow::Error> {
    let workspace_id = self.user_service.workspace_id()?;
    let config = self
      .cloud_service
      .get_local_ai_config(&workspace_id)
      .await?;
    Ok(config)
  }

  fn store(&self, setting: LLMSetting) -> Result<(), Error> {
    self
      .store_preferences
      .set_object(LOCAL_AI_SETTING_KEY, setting)?;
    Ok(())
  }

  fn retrieve(&self) -> Option<LLMSetting> {
    self
      .store_preferences
      .get_object::<LLMSetting>(LOCAL_AI_SETTING_KEY)
  }
}

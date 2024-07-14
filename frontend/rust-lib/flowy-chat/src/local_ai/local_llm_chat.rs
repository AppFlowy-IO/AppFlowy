use crate::chat_manager::ChatUserService;
use crate::entities::{
  ChatPluginStatePB, ChatStatePB, LocalModelResourcePB, ModelTypePB, RunningStatePB,
};
use crate::local_ai::llm_resource::{LLMResourceController, LLMResourceService};
use crate::notification::{send_notification, ChatNotification};
use anyhow::Error;
use appflowy_local_ai::chat_plugin::{ChatPluginConfig, LocalChatLLMChat};
use appflowy_plugin::manager::PluginManager;
use appflowy_plugin::util::is_apple_silicon;
use flowy_chat_pub::cloud::{AppFlowyAIPlugin, ChatCloudService, LLMModel, LocalAIConfig};
use flowy_error::FlowyResult;
use flowy_sqlite::kv::KVStorePreferences;
use futures::Sink;
use lib_infra::async_trait::async_trait;

use serde::{Deserialize, Serialize};
use std::ops::Deref;

use std::sync::Arc;
use tokio_stream::StreamExt;
use tracing::{error, info, trace};

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
pub struct LocalLLMController {
  llm_chat: Arc<LocalChatLLMChat>,
  llm_res: Arc<LLMResourceController>,
}

impl Deref for LocalLLMController {
  type Target = Arc<LocalChatLLMChat>;

  fn deref(&self) -> &Self::Target {
    &self.llm_chat
  }
}

impl LocalLLMController {
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
        let new_state = RunningStatePB::from(state);
        info!("[Chat Plugin] state: {:?}", new_state);
        send_notification(
          "appflowy_chat_plugin",
          ChatNotification::UpdateChatPluginState,
        )
        .payload(ChatPluginStatePB { state: new_state });
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
        if let Ok(chat_config) = cloned_llm_res.get_chat_config() {
          initialize_chat_plugin(&cloned_llm_chat, chat_config).unwrap();
        }
      }
    });

    Self { llm_chat, llm_res }
  }
  pub async fn refresh(&self) -> FlowyResult<LLMModelInfo> {
    self.llm_res.refresh_llm_resource().await
  }

  pub fn initialize(&self) -> FlowyResult<()> {
    let chat_config = self.llm_res.get_chat_config()?;
    let llm_chat = self.llm_chat.clone();
    initialize_chat_plugin(&llm_chat, chat_config)?;
    Ok(())
  }

  /// Returns true if the local AI is enabled and ready to use.
  pub fn is_ready(&self) -> bool {
    self.llm_res.is_ready()
  }

  pub fn open_chat(&self, chat_id: &str) {
    if !self.is_ready() {
      return;
    }

    let chat_id = chat_id.to_string();
    let weak_ctrl = Arc::downgrade(&self.llm_chat);
    tokio::spawn(async move {
      if let Some(ctrl) = weak_ctrl.upgrade() {
        if let Err(err) = ctrl.create_chat(&chat_id).await {
          error!("[Chat Plugin] failed to open chat: {:?}", err);
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
          error!("[Chat Plugin] failed to close chat: {:?}", err);
        }
      }
    });
  }

  pub async fn use_local_llm(&self, llm_id: i64) -> FlowyResult<LocalModelResourcePB> {
    let llm_chat = self.llm_chat.clone();
    match llm_chat.destroy_chat_plugin().await {
      Ok(_) => info!("[Chat Plugin] destroy plugin successfully"),
      Err(err) => error!("[Chat Plugin] failed to destroy plugin: {:?}", err),
    }
    let state = self.llm_res.use_local_llm(llm_id)?;
    // Re-initialize the plugin if the setting is updated and ready to use
    if self.llm_res.is_ready() {
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
}

fn initialize_chat_plugin(
  llm_chat: &Arc<LocalChatLLMChat>,
  mut chat_config: ChatPluginConfig,
) -> FlowyResult<()> {
  let llm_chat = llm_chat.clone();
  tokio::spawn(async move {
    trace!("[Chat Plugin] config: {:?}", chat_config);
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
        error!("[Chat Plugin] failed to setup plugin: {:?}", err);
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

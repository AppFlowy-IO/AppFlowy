use anyhow::Result;
use flowy_sidecar::manager::SidecarManager;
use flowy_sidecar::parser::{ChatResponseParser, SimilarityResponseParser};
use flowy_sidecar::plugin::{PluginId, PluginInfo};
use serde_json::json;
use std::sync::Once;

use tracing_subscriber::fmt::Subscriber;
use tracing_subscriber::util::SubscriberInitExt;
use tracing_subscriber::EnvFilter;

pub struct LocalAITest {
  config: LocalAIConfiguration,
  manager: SidecarManager,
}

impl LocalAITest {
  pub fn new() -> Result<Self> {
    let config = LocalAIConfiguration::new()?;
    let manager = SidecarManager::new();

    Ok(Self { config, manager })
  }
  pub async fn init_chat_plugin(&self) -> PluginId {
    let info = PluginInfo {
      name: "chat".to_string(),
      exec_path: self.config.chat_bin_path.clone(),
    };
    let plugin_id = self.manager.create_plugin(info).await.unwrap();
    self
      .manager
      .init_plugin(
        plugin_id,
        json!({
            "absolute_chat_model_path":self.config.chat_model_absolute_path(),
        }),
      )
      .unwrap();

    plugin_id
  }

  pub async fn init_embedding_plugin(&self) -> PluginId {
    let info = PluginInfo {
      name: "embedding".to_string(),
      exec_path: self.config.embedding_bin_path.clone(),
    };
    let plugin_id = self.manager.create_plugin(info).await.unwrap();
    let embedding_model_path = self.config.embedding_model_absolute_path();
    self
      .manager
      .init_plugin(
        plugin_id,
        json!({
            "absolute_model_path":embedding_model_path,
        }),
      )
      .unwrap();
    plugin_id
  }

  pub async fn send_message(&self, chat_id: &str, plugin_id: PluginId, message: &str) -> String {
    let resp = self
      .manager
      .async_send_request::<ChatResponseParser>(
        plugin_id,
        "handle",
        json!({"chat_id": chat_id, "method": "answer", "params": {"content": message}}),
      )
      .await
      .unwrap();

    resp
  }

  pub async fn calculate_similarity(
    &self,
    plugin_id: PluginId,
    message1: &str,
    message2: &str,
  ) -> f64 {
    self
      .manager
      .async_send_request::<SimilarityResponseParser>(
        plugin_id,
        "handle",
        json!({"method": "calculate_similarity", "params": {"src": message1, "dest": message2}}),
      )
      .await
      .unwrap()
  }
}

pub struct LocalAIConfiguration {
  root: String,
  chat_bin_path: String,
  chat_model_name: String,
  embedding_bin_path: String,
  embedding_model_name: String,
}

impl LocalAIConfiguration {
  pub fn new() -> Result<Self> {
    dotenv::dotenv().ok();
    setup_log();

    // load from .env
    let root = dotenv::var("LOCAL_AI_ROOT_PATH")?;
    let chat_bin_path = dotenv::var("CHAT_BIN_PATH")?;
    let chat_model_name = dotenv::var("LOCAL_AI_CHAT_MODEL_NAME")?;

    let embedding_bin_path = dotenv::var("EMBEDDING_BIN_PATH")?;
    let embedding_model_name = dotenv::var("LOCAL_AI_EMBEDDING_MODEL_NAME")?;

    Ok(Self {
      root,
      chat_bin_path,
      chat_model_name,
      embedding_bin_path,
      embedding_model_name,
    })
  }

  pub fn chat_model_absolute_path(&self) -> String {
    format!("{}/{}", self.root, self.chat_model_name)
  }

  pub fn embedding_model_absolute_path(&self) -> String {
    format!("{}/{}", self.root, self.embedding_model_name)
  }
}

pub fn setup_log() {
  static START: Once = Once::new();
  START.call_once(|| {
    let level = "trace";
    let mut filters = vec![];
    filters.push(format!("flowy_sidecar={}", level));
    std::env::set_var("RUST_LOG", filters.join(","));

    let subscriber = Subscriber::builder()
      .with_env_filter(EnvFilter::from_default_env())
      .with_line_number(true)
      .with_ansi(true)
      .finish();
    subscriber.try_init().unwrap();
  });
}

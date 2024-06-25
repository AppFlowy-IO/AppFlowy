use anyhow::Result;
use flowy_sidecar::manager::SidecarManager;
use flowy_sidecar::parser::ChatResponseParser;
use flowy_sidecar::plugin::PluginInfo;
use serde_json::json;
use std::sync::Once;

use tracing_subscriber::fmt::Subscriber;
use tracing_subscriber::util::SubscriberInitExt;
use tracing_subscriber::EnvFilter;

#[tokio::test]
async fn load_chat_model_test() {
  if let Ok(config) = LocalAIConfiguration::new() {
    let manager = SidecarManager::new();
    let info = PluginInfo {
      name: "chat".to_string(),
      exec_path: config.chat_bin_path.clone(),
    };
    let plugin_id = manager.create_plugin(info).await.unwrap();
    manager
      .init_plugin(
        plugin_id,
        json!({
            "absolute_chat_model_path":config.chat_model_absolute_path(),
        }),
      )
      .unwrap();

    let _json = json!({
        "plugin_id": "example_plugin_id",
        "method": "initialize",
        "params": {
            "absolute_chat_model_path":config.chat_model_absolute_path(),
        }
    });

    let chat_id = uuid::Uuid::new_v4().to_string();
    let resp = manager
      .send_request::<ChatResponseParser>(
        plugin_id,
        "handle",
        json!({"chat_id": chat_id, "method": "answer", "params": {"content": "hello world"}}),
      )
      .unwrap();

    eprintln!("chat response: {:?}", resp);
  }
}

pub struct LocalAIConfiguration {
  root: String,
  chat_bin_path: String,
  chat_model_name: String,
}

impl LocalAIConfiguration {
  pub fn new() -> Result<Self> {
    dotenv::dotenv().ok();
    setup_log();

    // load from .env
    let root = dotenv::var("LOCAL_AI_ROOT_PATH")?;
    let chat_bin_path = dotenv::var("CHAT_BIN_PATH")?;
    let chat_model = dotenv::var("LOCAL_AI_CHAT_MODEL_NAME")?;

    Ok(Self {
      root,
      chat_bin_path,
      chat_model_name: chat_model,
    })
  }

  pub fn chat_model_absolute_path(&self) -> String {
    format!("{}/{}", self.root, self.chat_model_name)
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

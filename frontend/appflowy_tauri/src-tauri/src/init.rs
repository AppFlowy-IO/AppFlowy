use dotenv::dotenv;
use flowy_core::config::AppFlowyCoreConfig;
use flowy_core::{AppFlowyCore, DEFAULT_NAME};
use lib_dispatch::runtime::AFPluginRuntime;
use std::sync::Mutex;

pub fn read_env() {
  dotenv().ok();

  let env = if cfg!(debug_assertions) {
    include_str!("../env.development")
  } else {
    include_str!("../env.production")
  };

  for line in env.lines() {
    if let Some((key, value)) = line.split_once('=') {
      // Check if the environment variable is not already set in the system
      let current_value = std::env::var(key).unwrap_or_default();
      if current_value.is_empty() {
        std::env::set_var(key, value);
      }
    }
  }
}

pub(crate) fn init_appflowy_core() -> MutexAppFlowyCore {
  let config_json = include_str!("../tauri.conf.json");
  let config: tauri_utils::config::Config = serde_json::from_str(config_json).unwrap();

  let app_version = config
    .package
    .version
    .clone()
    .map(|v| v.to_string())
    .unwrap_or_else(|| "0.5.8".to_string());
  let app_version =
    semver::Version::parse(&app_version).unwrap_or_else(|_| semver::Version::new(0, 5, 8));
  let mut data_path = tauri::api::path::app_local_data_dir(&config).unwrap();
  if cfg!(debug_assertions) {
    data_path.push("data_dev");
  } else {
    data_path.push("data");
  }

  let custom_application_path = data_path.to_str().unwrap().to_string();
  let application_path = data_path.to_str().unwrap().to_string();
  let device_id = uuid::Uuid::new_v4().to_string();

  read_env();
  std::env::set_var("RUST_LOG", "trace");

  let config = AppFlowyCoreConfig::new(
    app_version,
    custom_application_path,
    application_path,
    device_id,
    "tauri".to_string(),
    DEFAULT_NAME.to_string(),
  )
  .log_filter("trace", vec!["appflowy_tauri".to_string()]);

  let runtime = Arc::new(AFPluginRuntime::new().unwrap());
  let cloned_runtime = runtime.clone();
  runtime.block_on(async move {
    MutexAppFlowyCore::new(AppFlowyCore::new(config, cloned_runtime, None).await)
  })
}

pub struct MutexAppFlowyCore(pub Arc<Mutex<AppFlowyCore>>);

impl MutexAppFlowyCore {
  fn new(appflowy_core: AppFlowyCore) -> Self {
    Self(Arc::new(Mutex::new(appflowy_core)))
  }
}
unsafe impl Sync for MutexAppFlowyCore {}
unsafe impl Send for MutexAppFlowyCore {}

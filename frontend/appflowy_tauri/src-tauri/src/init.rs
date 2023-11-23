use flowy_core::config::AppFlowyCoreConfig;
use flowy_core::{AppFlowyCore, DEFAULT_NAME};

pub fn init_flowy_core() -> AppFlowyCore {
  let config_json = include_str!("../tauri.conf.json");
  let config: tauri_utils::config::Config = serde_json::from_str(config_json).unwrap();

  let mut data_path = tauri::api::path::app_local_data_dir(&config).unwrap();
  if cfg!(debug_assertions) {
    data_path.push("data_dev");
  } else {
    data_path.push("data");
  }

  let custom_application_path = data_path.to_str().unwrap().to_string();
  let application_path = data_path.to_str().unwrap().to_string();
  let device_id = uuid::Uuid::new_v4().to_string();

  std::env::set_var("RUST_LOG", "trace");
  let config = AppFlowyCoreConfig::new(
    custom_application_path,
    application_path,
    device_id,
    DEFAULT_NAME.to_string(),
  )
  .log_filter("trace", vec!["appflowy_tauri".to_string()]);
  AppFlowyCore::new(config)
}

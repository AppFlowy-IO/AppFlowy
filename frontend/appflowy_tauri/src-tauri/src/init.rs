use flowy_core::{AppFlowyCore, AppFlowyCoreConfig, DEFAULT_NAME};

pub fn init_flowy_core() -> AppFlowyCore {
  let config_json = include_str!("../tauri.conf.json");
  let config: tauri_utils::config::Config = serde_json::from_str(config_json).unwrap();

  let mut data_path = tauri::api::path::app_local_data_dir(&config).unwrap();
  if cfg!(debug_assertions) {
    data_path.push("dev");
  }
  data_path.push("data");

  std::env::set_var("RUST_LOG", "trace");
  let config = AppFlowyCoreConfig::new(data_path.to_str().unwrap(), DEFAULT_NAME.to_string())
    .log_filter("trace", vec!["appflowy_tauri".to_string()]);
  AppFlowyCore::new(config)
}

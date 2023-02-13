use flowy_core::{get_client_server_configuration, AppFlowyCore, AppFlowyCoreConfig};

pub fn init_flowy_core() -> AppFlowyCore {
  let data_path = tauri::api::path::data_dir().unwrap();
  let path = format!("{}/AppFlowy", data_path.to_str().unwrap());
  let server_config = get_client_server_configuration().unwrap();
  let config = AppFlowyCoreConfig::new(&path, "AppFlowy".to_string(), server_config)
    .log_filter("trace", vec!["appflowy_tauri".to_string()]);
  AppFlowyCore::new(config)
}

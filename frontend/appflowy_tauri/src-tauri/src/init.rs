use flowy_core::{get_client_server_configuration, AppFlowyCore, AppFlowyCoreConfig};

pub fn init_flowy_core() -> AppFlowyCore {
    let config_json = include_str!("../tauri.conf.json");
    let config: tauri_utils::config::Config = serde_json::from_str(config_json).unwrap();

    let mut data_path = tauri::api::path::app_local_data_dir(&config).unwrap();
    if cfg!(debug_assertions) {
        data_path.push("dev");
    }
    data_path.push("data");

    std::env::set_var("RUST_LOG", "trace");
    let server_config = get_client_server_configuration().unwrap();
    let config = AppFlowyCoreConfig::new(
        data_path.to_str().unwrap(),
        "AppFlowy".to_string(),
        server_config,
    )
        .log_filter("trace", vec!["appflowy_tauri".to_string()]);
    AppFlowyCore::new(config)
}

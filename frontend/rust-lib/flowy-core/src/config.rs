use std::fmt;
use std::path::Path;

use base64::Engine;
use tracing::{error, info};

use flowy_server_config::af_cloud_config::AFCloudConfiguration;
use flowy_server_config::supabase_config::SupabaseConfiguration;
use flowy_user::manager::URL_SAFE_ENGINE;

use crate::integrate::log::create_log_filter;
use crate::integrate::util::copy_dir_recursive;

#[derive(Clone)]
pub struct AppFlowyCoreConfig {
  /// Different `AppFlowyCoreConfig` instance should have different name
  pub(crate) name: String,
  /// Panics if the `root` path is not existing
  pub storage_path: String,
  pub(crate) log_filter: String,
  cloud_config: Option<AFCloudConfiguration>,
}

impl fmt::Debug for AppFlowyCoreConfig {
  fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
    let mut debug = f.debug_struct("AppFlowy Configuration");
    debug.field("storage_path", &self.storage_path);
    if let Some(config) = &self.cloud_config {
      debug.field("base_url", &config.base_url);
      debug.field("ws_url", &config.ws_base_url);
    }
    debug.finish()
  }
}

fn migrate_local_version_data_folder(root: &str, url: &str) -> String {
  // Isolate the user data folder by using the base url of AppFlowy cloud. This is to avoid
  // the user data folder being shared by different AppFlowy cloud.
  let server_base64 = URL_SAFE_ENGINE.encode(&url);
  let storage_path = format!("{}_{}", root, server_base64);

  // Copy the user data folder from the root path to the isolated path
  // The root path without any suffix is the created by the local version AppFlowy
  if !Path::new(&storage_path).exists() && Path::new(root).exists() {
    info!("Copy dir from {} to {}", root, storage_path);
    let src = Path::new(root);
    match copy_dir_recursive(&src, Path::new(&storage_path)) {
      Ok(_) => storage_path,
      Err(err) => {
        // when the copy dir failed, use the root path as the storage path
        error!("Copy dir failed: {}", err);
        root.to_string()
      },
    }
  } else {
    storage_path
  }
}

impl AppFlowyCoreConfig {
  pub fn new(root: &str, name: String) -> Self {
    let cloud_config = AFCloudConfiguration::from_env().ok();
    let storage_path = match &cloud_config {
      None => {
        let supabase_config = SupabaseConfiguration::from_env().ok();
        match &supabase_config {
          None => root.to_string(),
          Some(config) => migrate_local_version_data_folder(root, &config.url),
        }
      },
      Some(config) => migrate_local_version_data_folder(root, &config.base_url),
    };

    AppFlowyCoreConfig {
      name,
      storage_path,
      log_filter: create_log_filter("info".to_owned(), vec![]),
      cloud_config,
    }
  }

  pub fn log_filter(mut self, level: &str, with_crates: Vec<String>) -> Self {
    self.log_filter = create_log_filter(level.to_owned(), with_crates);
    self
  }
}

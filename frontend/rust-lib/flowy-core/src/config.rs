use std::fmt;
use std::path::{Path, PathBuf};

use base64::Engine;
use semver::Version;
use tracing::{error, info};
use url::Url;

use crate::log_filter::create_log_filter;
use flowy_server_pub::af_cloud_config::AFCloudConfiguration;
use flowy_user::services::entities::URL_SAFE_ENGINE;
use lib_infra::file_util::copy_dir_recursive;
use lib_infra::util::OperatingSystem;

#[derive(Clone)]
pub struct AppFlowyCoreConfig {
  /// Different `AppFlowyCoreConfig` instance should have different name
  pub(crate) app_version: Version,
  pub name: String,
  pub(crate) device_id: String,
  pub platform: String,
  /// Used to store the user data
  pub storage_path: String,
  /// Origin application path is the path of the application binary. By default, the
  /// storage_path is the same as the origin_application_path. However, when the user
  /// choose a custom path for the user data, the storage_path will be different from
  /// the origin_application_path.
  pub application_path: String,
  pub(crate) log_filter: String,
  pub cloud_config: Option<AFCloudConfiguration>,
}
impl AppFlowyCoreConfig {
  pub fn ensure_path(&self) {
    let create_if_needed = |path_str: &str, label: &str| {
      let dir = std::path::Path::new(path_str);
      if !dir.exists() {
        match std::fs::create_dir_all(dir) {
          Ok(_) => info!("Created {} path: {}", label, path_str),
          Err(err) => error!(
            "Failed to create {} path: {}. Error: {}",
            label, path_str, err
          ),
        }
      }
    };

    create_if_needed(&self.storage_path, "storage");
    create_if_needed(&self.application_path, "application");
  }
}
impl fmt::Debug for AppFlowyCoreConfig {
  fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
    let mut debug = f.debug_struct("AppFlowy Configuration");
    debug.field("app_version", &self.app_version);
    debug.field("storage_path", &self.storage_path);
    debug.field("application_path", &self.application_path);
    if let Some(config) = &self.cloud_config {
      debug.field("base_url", &config.base_url);
      debug.field("ws_url", &config.ws_base_url);
      debug.field("gotrue_url", &config.gotrue_url);
      debug.field("enable_sync_trace", &config.enable_sync_trace);
    }
    debug.finish()
  }
}

fn make_user_data_folder(root: &str, url: &str) -> String {
  // If a URL is provided, try to parse it and extract the domain name.
  // This isolates the user data folder by the domain, which prevents data sharing
  // between different AppFlowy cloud instances.
  print!("Creating user data folder for URL: {}, root:{}", url, root);
  let mut storage_path = if url.is_empty() {
    PathBuf::from(root)
  } else {
    let server_base64 = URL_SAFE_ENGINE.encode(url);
    PathBuf::from(format!("{}_{}", root, server_base64))
  };

  // Only use new storage path if the old one doesn't exist
  if !storage_path.exists() {
    let anon_path = format!("{}_anonymous", root);
    // We use domain name as suffix to isolate the user data folder since version 0.8.9
    let new_storage_path = if url.is_empty() {
      // if the url is empty, then it's anonymous mode
      anon_path
    } else {
      match Url::parse(url) {
        Ok(parsed_url) => {
          if let Some(domain) = parsed_url.host_str() {
            format!("{}_{}", root, domain)
          } else {
            anon_path
          }
        },
        Err(_) => anon_path,
      }
    };

    storage_path = PathBuf::from(new_storage_path);
  }

  // Copy the user data folder from the root path to the isolated path
  // The root path without any suffix is the created by the local version AppFlowy
  if !storage_path.exists() && Path::new(root).exists() {
    info!("Copy dir from {} to {:?}", root, storage_path);
    let src = Path::new(root);
    match copy_dir_recursive(src, &storage_path) {
      Ok(_) => storage_path
        .into_os_string()
        .into_string()
        .unwrap_or_else(|_| root.to_string()),
      Err(err) => {
        error!("Copy dir failed: {}", err);
        root.to_string()
      },
    }
  } else {
    storage_path
      .into_os_string()
      .into_string()
      .unwrap_or_else(|_| root.to_string())
  }
}

impl AppFlowyCoreConfig {
  pub fn new(
    app_version: Version,
    custom_application_path: String,
    application_path: String,
    device_id: String,
    platform: String,
    name: String,
  ) -> Self {
    let cloud_config = AFCloudConfiguration::from_env().ok();
    // By default enable sync trace log
    let log_crates = vec!["sync_trace_log".to_string()];
    let storage_path = match &cloud_config {
      None => custom_application_path,
      Some(config) => make_user_data_folder(&custom_application_path, &config.base_url),
    };

    let log_filter = create_log_filter(
      "info".to_owned(),
      log_crates,
      OperatingSystem::from(&platform),
    );

    AppFlowyCoreConfig {
      app_version,
      name,
      storage_path,
      application_path,
      device_id,
      platform,
      log_filter,
      cloud_config,
    }
  }

  pub fn log_filter(mut self, level: &str, with_crates: Vec<String>) -> Self {
    self.log_filter = create_log_filter(
      level.to_owned(),
      with_crates,
      OperatingSystem::from(&self.platform),
    );
    self
  }
}

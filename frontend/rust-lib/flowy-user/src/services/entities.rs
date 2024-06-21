use base64::alphabet::URL_SAFE;
use std::fs;
use std::path::PathBuf;

use crate::services::db::UserDBPath;
use base64::engine::general_purpose::PAD;
use base64::engine::GeneralPurpose;
use semver::Version;

pub const URL_SAFE_ENGINE: GeneralPurpose = GeneralPurpose::new(&URL_SAFE, PAD);
#[derive(Clone)]
pub struct UserConfig {
  /// Used to store the user data
  pub storage_path: String,
  /// application_path is the path of the application binary. By default, the
  /// storage_path is the same as the application_path. However, when the user
  /// choose a custom path for the user data, the storage_path will be different from
  /// the application_path.
  pub application_path: String,
  pub device_id: String,
  /// Used as the key of `Session` when saving session information to KV.
  pub(crate) session_cache_key: String,
  pub app_version: Version,
}

impl UserConfig {
  /// The `root_dir` represents as the root of the user folders. It must be unique for each
  /// users.
  pub fn new(
    name: &str,
    storage_path: &str,
    application_path: &str,
    device_id: &str,
    app_version: Version,
  ) -> Self {
    let session_cache_key = format!("{}_session_cache", name);
    Self {
      storage_path: storage_path.to_owned(),
      application_path: application_path.to_owned(),
      session_cache_key,
      device_id: device_id.to_owned(),
      app_version,
    }
  }

  /// Returns bool whether the user choose a custom path for the user data.
  pub fn is_custom_storage_path(&self) -> bool {
    !self.storage_path.contains(&self.application_path)
  }
}

#[derive(Clone)]
pub struct UserPaths {
  root: String,
}

impl UserPaths {
  pub fn new(root: String) -> Self {
    Self { root }
  }

  /// Returns the path to the user's data directory.
  pub(crate) fn user_data_dir(&self, uid: i64) -> String {
    format!("{}/{}", self.root, uid)
  }

  /// The root directory of the application
  pub(crate) fn root(&self) -> &str {
    &self.root
  }
}

impl UserDBPath for UserPaths {
  fn sqlite_db_path(&self, uid: i64) -> PathBuf {
    PathBuf::from(self.user_data_dir(uid))
  }

  fn collab_db_path(&self, uid: i64) -> PathBuf {
    let mut path = PathBuf::from(self.user_data_dir(uid));
    path.push("collab_db");
    path
  }

  fn collab_db_history(&self, uid: i64, create_if_not_exist: bool) -> std::io::Result<PathBuf> {
    let path = PathBuf::from(self.user_data_dir(uid)).join("collab_db_history");
    if !path.exists() && create_if_not_exist {
      fs::create_dir_all(&path)?;
    }
    Ok(path)
  }
}

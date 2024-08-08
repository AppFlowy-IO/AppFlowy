use std::sync::Weak;

use flowy_error::FlowyError;
use flowy_storage_pub::cloud::{FileStoragePlan, StorageObject};
use lib_infra::future::FutureResult;

use crate::supabase::api::RESTfulPostgresServer;

#[derive(Default)]
pub struct FileStoragePlanImpl {
  #[allow(dead_code)]
  uid: Weak<RwLock<Option<i64>>>,
  #[allow(dead_code)]
  postgrest: Option<Weak<RESTfulPostgresServer>>,
}

impl FileStoragePlanImpl {
  pub fn new(
    uid: Weak<RwLock<Option<i64>>>,
    postgrest: Option<Weak<RESTfulPostgresServer>>,
  ) -> Self {
    Self { uid, postgrest }
  }
}

impl FileStoragePlan for FileStoragePlanImpl {
  fn storage_size(&self) -> FutureResult<u64, FlowyError> {
    // 1 GB
    FutureResult::new(async { Ok(1024 * 1024 * 1024) })
  }

  fn maximum_file_size(&self) -> FutureResult<u64, FlowyError> {
    // 5 MB
    FutureResult::new(async { Ok(5 * 1024 * 1024) })
  }

  fn check_upload_object(&self, _object: &StorageObject) -> FutureResult<(), FlowyError> {
    FutureResult::new(async { Ok(()) })
  }
}

use std::sync::Weak;

use parking_lot::RwLock;

use flowy_storage::error::FileStorageError;
use flowy_storage::{FileStoragePlan, StorageObject};
use lib_infra::future::FutureResult;

use crate::supabase::api::RESTfulPostgresServer;

#[derive(Default)]
pub struct FileStoragePlanImpl {
  uid: Weak<RwLock<Option<i64>>>,
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
  fn storage_size(&self) -> FutureResult<u64, FileStorageError> {
    // 1 GB
    FutureResult::new(async { Ok(1 * 1024 * 1024 * 1024) })
  }

  fn maximum_file_size(&self) -> FutureResult<u64, FileStorageError> {
    // 5 MB
    FutureResult::new(async { Ok(5 * 1024 * 1024) })
  }

  fn check_upload_object(&self, object: &StorageObject) -> FutureResult<(), FileStorageError> {
    FutureResult::new(async { Ok(()) })
  }
}

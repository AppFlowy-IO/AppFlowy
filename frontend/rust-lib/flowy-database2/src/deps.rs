use std::sync::Arc;

use appflowy_integrate::RocksCollabDB;

use flowy_error::FlowyError;
use lib_infra::future::FutureResult;

pub trait DatabaseUser2: Send + Sync {
  fn user_id(&self) -> Result<i64, FlowyError>;
  fn token(&self) -> Result<Option<String>, FlowyError>;
  fn collab_db(&self) -> Result<Arc<RocksCollabDB>, FlowyError>;
}

pub trait DatabaseCloudService: Send + Sync {
  fn get_latest_snapshot(&self, database_id: &str) -> FutureResult<Option<Vec<u8>>, FlowyError>;
}

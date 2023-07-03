use std::sync::Arc;

use appflowy_integrate::RocksCollabDB;

use flowy_error::FlowyError;
use lib_infra::future::FutureResult;

pub trait DocumentUser: Send + Sync {
  fn user_id(&self) -> Result<i64, FlowyError>;
  fn token(&self) -> Result<Option<String>, FlowyError>; // unused now.
  fn collab_db(&self) -> Result<Arc<RocksCollabDB>, FlowyError>;
}

/// A trait for document cloud service.
/// Each kind of server should implement this trait. Check out the [AppFlowyServerProvider] of
/// [flowy-server] crate for more information.
pub trait DocumentCloudService: Send + Sync + 'static {
  fn get_latest_snapshot(&self, document_id: &str) -> FutureResult<Option<Vec<u8>>, FlowyError>;
}

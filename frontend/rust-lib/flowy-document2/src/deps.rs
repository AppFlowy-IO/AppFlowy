use std::sync::Arc;

use appflowy_integrate::RocksCollabDB;
pub use collab_document::blocks::DocumentData;

use flowy_error::FlowyError;
use lib_infra::future::FutureResult;

pub trait DocumentUser: Send + Sync {
  fn user_id(&self) -> Result<i64, FlowyError>;
  fn token(&self) -> Result<Option<String>, FlowyError>; // unused now.
  fn collab_db(&self, uid: i64) -> Result<Arc<RocksCollabDB>, FlowyError>;
}

/// A trait for document cloud service.
/// Each kind of server should implement this trait. Check out the [AppFlowyServerProvider] of
/// [flowy-server] crate for more information.
pub trait DocumentCloudService: Send + Sync + 'static {
  fn get_document_updates(&self, document_id: &str) -> FutureResult<Vec<Vec<u8>>, FlowyError>;

  fn get_document_latest_snapshot(
    &self,
    document_id: &str,
  ) -> FutureResult<Option<DocumentSnapshot>, FlowyError>;

  fn get_document_data(&self, document_id: &str) -> FutureResult<Option<DocumentData>, FlowyError>;
}

pub struct DocumentSnapshot {
  pub snapshot_id: i64,
  pub document_id: String,
  pub data: Vec<u8>,
  pub created_at: i64,
}

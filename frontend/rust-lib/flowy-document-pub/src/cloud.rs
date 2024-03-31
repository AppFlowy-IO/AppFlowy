use anyhow::Error;
pub use collab_document::blocks::DocumentData;

use flowy_error::FlowyError;
use lib_infra::future::FutureResult;

/// A trait for document cloud service.
/// Each kind of server should implement this trait. Check out the [AppFlowyServerProvider] of
/// [flowy-server] crate for more information.
pub trait DocumentCloudService: Send + Sync + 'static {
  fn get_document_doc_state(
    &self,
    document_id: &str,
    workspace_id: &str,
  ) -> FutureResult<Vec<u8>, FlowyError>;

  fn get_document_snapshots(
    &self,
    document_id: &str,
    limit: usize,
    workspace_id: &str,
  ) -> FutureResult<Vec<DocumentSnapshot>, Error>;

  fn get_document_data(
    &self,
    document_id: &str,
    workspace_id: &str,
  ) -> FutureResult<Option<DocumentData>, Error>;
}

pub struct DocumentSnapshot {
  pub snapshot_id: i64,
  pub document_id: String,
  pub data: Vec<u8>,
  pub created_at: i64,
}

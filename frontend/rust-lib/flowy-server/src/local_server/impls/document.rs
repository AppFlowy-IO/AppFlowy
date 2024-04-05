use anyhow::Error;

use flowy_document_pub::cloud::*;
use flowy_error::{ErrorCode, FlowyError};
use lib_infra::future::FutureResult;

pub(crate) struct LocalServerDocumentCloudServiceImpl();

impl DocumentCloudService for LocalServerDocumentCloudServiceImpl {
  fn get_document_doc_state(
    &self,
    document_id: &str,
    _workspace_id: &str,
  ) -> FutureResult<Vec<u8>, FlowyError> {
    let document_id = document_id.to_string();
    FutureResult::new(async move {
      Err(FlowyError::new(
        ErrorCode::RecordNotFound,
        format!("Document {} not found", document_id),
      ))
    })
  }

  fn get_document_snapshots(
    &self,
    _document_id: &str,
    _limit: usize,
    _workspace_id: &str,
  ) -> FutureResult<Vec<DocumentSnapshot>, Error> {
    FutureResult::new(async move { Ok(vec![]) })
  }

  fn get_document_data(
    &self,
    _document_id: &str,
    _workspace_id: &str,
  ) -> FutureResult<Option<DocumentData>, Error> {
    FutureResult::new(async move { Ok(None) })
  }
}

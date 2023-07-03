use flowy_document2::deps::{DocumentCloudService, DocumentSnapshot};
use flowy_error::FlowyError;
use lib_infra::future::FutureResult;

pub(crate) struct LocalServerDocumentCloudServiceImpl();

impl DocumentCloudService for LocalServerDocumentCloudServiceImpl {
  fn get_latest_snapshot(
    &self,
    _document_id: &str,
  ) -> FutureResult<Option<DocumentSnapshot>, FlowyError> {
    FutureResult::new(async move { Ok(None) })
  }
}

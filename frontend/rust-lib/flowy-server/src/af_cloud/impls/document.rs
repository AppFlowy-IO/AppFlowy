use anyhow::Error;

use flowy_document_deps::cloud::*;
use lib_infra::future::FutureResult;

pub(crate) struct AFCloudDocumentCloudServiceImpl();

impl DocumentCloudService for AFCloudDocumentCloudServiceImpl {
  fn get_document_updates(&self, _document_id: &str) -> FutureResult<Vec<Vec<u8>>, Error> {
    FutureResult::new(async move { Ok(vec![]) })
  }

  fn get_document_snapshots(
    &self,
    _document_id: &str,
    _limit: usize,
  ) -> FutureResult<Vec<DocumentSnapshot>, Error> {
    FutureResult::new(async move { Ok(vec![]) })
  }

  fn get_document_data(&self, _document_id: &str) -> FutureResult<Option<DocumentData>, Error> {
    FutureResult::new(async move { Ok(None) })
  }
}

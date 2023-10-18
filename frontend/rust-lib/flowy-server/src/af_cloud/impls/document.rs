use anyhow::Error;
use client_api::entity::QueryCollabParams;
use collab::core::origin::CollabOrigin;
use collab_document::document::Document;
use collab_entity::CollabType;

use flowy_document_deps::cloud::*;
use flowy_error::FlowyError;
use lib_infra::future::FutureResult;

use crate::af_cloud::AFServer;

pub(crate) struct AFCloudDocumentCloudServiceImpl<T>(pub T);

impl<T> DocumentCloudService for AFCloudDocumentCloudServiceImpl<T>
where
  T: AFServer,
{
  fn get_document_updates(&self, document_id: &str) -> FutureResult<Vec<Vec<u8>>, Error> {
    let try_get_client = self.0.try_get_client();
    let document_id = document_id.to_string();
    FutureResult::new(async move {
      let params = QueryCollabParams {
        object_id: document_id.to_string(),
        collab_type: CollabType::Document,
      };
      let data = try_get_client?
        .get_collab(params)
        .await
        .map_err(FlowyError::from)?;
      Ok(vec![data])
    })
  }

  fn get_document_snapshots(
    &self,
    _document_id: &str,
    _limit: usize,
  ) -> FutureResult<Vec<DocumentSnapshot>, Error> {
    FutureResult::new(async move { Ok(vec![]) })
  }

  fn get_document_data(&self, document_id: &str) -> FutureResult<Option<DocumentData>, Error> {
    let try_get_client = self.0.try_get_client();
    let document_id = document_id.to_string();
    FutureResult::new(async move {
      let params = QueryCollabParams {
        object_id: document_id.clone(),
        collab_type: CollabType::Document,
      };
      let updates = vec![try_get_client?
        .get_collab(params)
        .await
        .map_err(FlowyError::from)?];
      let document = Document::from_updates(CollabOrigin::Empty, updates, &document_id, vec![])?;
      Ok(document.get_document_data().ok())
    })
  }
}

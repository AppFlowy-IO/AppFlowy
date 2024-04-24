use anyhow::Error;
use client_api::entity::{QueryCollab, QueryCollabParams};
use collab::core::collab::DataSource;
use collab::core::origin::CollabOrigin;
use collab_document::document::Document;
use collab_entity::CollabType;

use flowy_document_pub::cloud::*;
use flowy_error::FlowyError;
use lib_infra::future::FutureResult;

use crate::af_cloud::AFServer;

pub(crate) struct AFCloudDocumentCloudServiceImpl<T>(pub T);

impl<T> DocumentCloudService for AFCloudDocumentCloudServiceImpl<T>
where
  T: AFServer,
{
  fn get_document_doc_state(
    &self,
    document_id: &str,
    workspace_id: &str,
  ) -> FutureResult<Vec<u8>, FlowyError> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.0.try_get_client();
    let document_id = document_id.to_string();
    FutureResult::new(async move {
      let params = QueryCollabParams {
        workspace_id,
        inner: QueryCollab {
          object_id: document_id.to_string(),
          collab_type: CollabType::Document,
        },
      };
      let doc_state = try_get_client?
        .get_collab(params)
        .await
        .map_err(FlowyError::from)?
        .encode_collab
        .doc_state
        .to_vec();
      Ok(doc_state)
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
    document_id: &str,
    workspace_id: &str,
  ) -> FutureResult<Option<DocumentData>, Error> {
    let try_get_client = self.0.try_get_client();
    let document_id = document_id.to_string();
    let workspace_id = workspace_id.to_string();
    FutureResult::new(async move {
      let params = QueryCollabParams {
        workspace_id,
        inner: QueryCollab {
          object_id: document_id.clone(),
          collab_type: CollabType::Document,
        },
      };
      let doc_state = try_get_client?
        .get_collab(params)
        .await
        .map_err(FlowyError::from)?
        .encode_collab
        .doc_state
        .to_vec();
      let document = Document::from_doc_state(
        CollabOrigin::Empty,
        DataSource::DocStateV1(doc_state),
        &document_id,
        vec![],
      )?;
      Ok(document.get_document_data().ok())
    })
  }
}

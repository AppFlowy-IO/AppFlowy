use client_api::entity::{CreateCollabParams, QueryCollab, QueryCollabParams};
use collab::core::collab::DataSource;
use collab::core::origin::CollabOrigin;
use collab::entity::EncodedCollab;
use collab::preclude::Collab;
use collab_document::document::Document;
use collab_entity::CollabType;
use std::sync::Arc;
use tracing::instrument;

use flowy_document_pub::cloud::*;
use flowy_error::FlowyError;
use lib_infra::async_trait::async_trait;

use crate::af_cloud::define::ServerUser;
use crate::af_cloud::impls::util::check_request_workspace_id_is_match;
use crate::af_cloud::AFServer;

pub(crate) struct AFCloudDocumentCloudServiceImpl<T> {
  pub inner: T,
  pub user: Arc<dyn ServerUser>,
}

#[async_trait]
impl<T> DocumentCloudService for AFCloudDocumentCloudServiceImpl<T>
where
  T: AFServer,
{
  #[instrument(level = "debug", skip_all, fields(document_id = %document_id))]
  async fn get_document_doc_state(
    &self,
    document_id: &str,
    workspace_id: &str,
  ) -> Result<Vec<u8>, FlowyError> {
    let params = QueryCollabParams {
      workspace_id: workspace_id.to_string(),
      inner: QueryCollab::new(document_id.to_string(), CollabType::Document),
    };
    let doc_state = self
      .inner
      .try_get_client()?
      .get_collab(params)
      .await
      .map_err(FlowyError::from)?
      .encode_collab
      .doc_state
      .to_vec();

    check_request_workspace_id_is_match(
      workspace_id,
      &self.user,
      format!("get document doc state:{}", document_id),
    )?;

    Ok(doc_state)
  }

  async fn get_document_snapshots(
    &self,
    _document_id: &str,
    _limit: usize,
    _workspace_id: &str,
  ) -> Result<Vec<DocumentSnapshot>, FlowyError> {
    Ok(vec![])
  }

  #[instrument(level = "debug", skip_all)]
  async fn get_document_data(
    &self,
    document_id: &str,
    workspace_id: &str,
  ) -> Result<Option<DocumentData>, FlowyError> {
    let params = QueryCollabParams {
      workspace_id: workspace_id.to_string(),
      inner: QueryCollab::new(document_id.to_string(), CollabType::Document),
    };
    let doc_state = self
      .inner
      .try_get_client()?
      .get_collab(params)
      .await?
      .encode_collab
      .doc_state
      .to_vec();
    check_request_workspace_id_is_match(
      workspace_id,
      &self.user,
      format!("Get {} document", document_id),
    )?;
    let collab = Collab::new_with_source(
      CollabOrigin::Empty,
      document_id,
      DataSource::DocStateV1(doc_state),
      vec![],
      false,
    )?;
    let document = Document::open(collab)?;
    Ok(document.get_document_data().ok())
  }

  async fn create_document_collab(
    &self,
    workspace_id: &str,
    document_id: &str,
    encoded_collab: EncodedCollab,
  ) -> Result<(), FlowyError> {
    let params = CreateCollabParams {
      workspace_id: workspace_id.to_string(),
      object_id: document_id.to_string(),
      encoded_collab_v1: encoded_collab
        .encode_to_bytes()
        .map_err(|err| FlowyError::internal().with_context(err))?,
      collab_type: CollabType::Document,
    };
    self.inner.try_get_client()?.create_collab(params).await?;
    Ok(())
  }
}

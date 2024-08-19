use anyhow::Error;
use client_api::entity::{QueryCollab, QueryCollabParams};
use collab::core::collab::DataSource;
use collab::core::origin::CollabOrigin;
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
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.inner.try_get_client();
    let document_id = document_id.to_string();
    let cloned_user = self.user.clone();
    let params = QueryCollabParams {
      workspace_id: workspace_id.clone(),
      inner: QueryCollab::new(document_id.to_string(), CollabType::Document),
    };
    let doc_state = try_get_client?
      .get_collab(params)
      .await
      .map_err(FlowyError::from)?
      .encode_collab
      .doc_state
      .to_vec();

    check_request_workspace_id_is_match(
      &workspace_id,
      &cloned_user,
      format!("get document doc state:{}", document_id),
    )?;

    Ok(doc_state)
  }

  async fn get_document_snapshots(
    &self,
    _document_id: &str,
    _limit: usize,
    _workspace_id: &str,
  ) -> Result<Vec<DocumentSnapshot>, Error> {
    Ok(vec![])
  }

  #[instrument(level = "debug", skip_all)]
  async fn get_document_data(
    &self,
    document_id: &str,
    workspace_id: &str,
  ) -> Result<Option<DocumentData>, Error> {
    let try_get_client = self.inner.try_get_client();
    let document_id = document_id.to_string();
    let workspace_id = workspace_id.to_string();
    let cloned_user = self.user.clone();
    let params = QueryCollabParams {
      workspace_id: workspace_id.clone(),
      inner: QueryCollab::new(document_id.clone(), CollabType::Document),
    };
    let doc_state = try_get_client?
      .get_collab(params)
      .await
      .map_err(FlowyError::from)?
      .encode_collab
      .doc_state
      .to_vec();
    check_request_workspace_id_is_match(
      &workspace_id,
      &cloned_user,
      format!("Get {} document", document_id),
    )?;
    let document = Document::open_with_options(
      CollabOrigin::Empty,
      DataSource::DocStateV1(doc_state),
      &document_id,
      vec![],
    )?;
    Ok(document.get_document_data().ok())
  }
}

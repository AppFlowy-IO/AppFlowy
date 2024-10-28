use client_api::entity::ai_dto::{
  SummarizeRowData, SummarizeRowParams, TranslateRowData, TranslateRowParams,
};
use client_api::entity::QueryCollabResult::{Failed, Success};
use client_api::entity::{CreateCollabParams, QueryCollab, QueryCollabParams};
use client_api::error::ErrorCode::RecordNotFound;
use collab::entity::EncodedCollab;
use collab_entity::CollabType;
use serde_json::{Map, Value};
use std::sync::Arc;
use tracing::{error, instrument};

use flowy_database_pub::cloud::{
  DatabaseAIService, DatabaseCloudService, DatabaseSnapshot, EncodeCollabByOid, SummaryRowContent,
  TranslateRowContent, TranslateRowResponse,
};
use flowy_error::FlowyError;
use lib_infra::async_trait::async_trait;

use crate::af_cloud::define::ServerUser;
use crate::af_cloud::impls::util::check_request_workspace_id_is_match;
use crate::af_cloud::AFServer;

pub(crate) struct AFCloudDatabaseCloudServiceImpl<T> {
  pub inner: T,
  pub user: Arc<dyn ServerUser>,
}

#[async_trait]
impl<T> DatabaseCloudService for AFCloudDatabaseCloudServiceImpl<T>
where
  T: AFServer,
{
  #[instrument(level = "debug", skip_all, err)]
  #[allow(clippy::blocks_in_conditions)]
  async fn get_database_encode_collab(
    &self,
    object_id: &str,
    collab_type: CollabType,
    workspace_id: &str,
  ) -> Result<Option<EncodedCollab>, FlowyError> {
    let workspace_id = workspace_id.to_string();
    let object_id = object_id.to_string();
    let try_get_client = self.inner.try_get_client();
    let cloned_user = self.user.clone();
    let params = QueryCollabParams {
      workspace_id: workspace_id.clone(),
      inner: QueryCollab::new(object_id.clone(), collab_type.clone()),
    };
    match try_get_client?.get_collab(params).await {
      Ok(data) => {
        check_request_workspace_id_is_match(
          &workspace_id,
          &cloned_user,
          format!("get database object: {}:{}", object_id, collab_type),
        )?;
        Ok(Some(data.encode_collab))
      },
      Err(err) => {
        if err.code == RecordNotFound {
          Ok(None)
        } else {
          Err(err.into())
        }
      },
    }
  }

  #[instrument(level = "debug", skip_all, err)]
  async fn create_database_encode_collab(
    &self,
    object_id: &str,
    collab_type: CollabType,
    workspace_id: &str,
    encoded_collab: EncodedCollab,
  ) -> Result<(), FlowyError> {
    let params = CreateCollabParams {
      workspace_id: workspace_id.to_string(),
      object_id: object_id.to_string(),
      encoded_collab_v1: encoded_collab
        .encode_to_bytes()
        .map_err(|err| FlowyError::internal().with_context(err))?,
      collab_type,
    };
    self.inner.try_get_client()?.create_collab(params).await?;
    Ok(())
  }

  #[instrument(level = "debug", skip_all)]
  async fn batch_get_database_encode_collab(
    &self,
    object_ids: Vec<String>,
    object_ty: CollabType,
    workspace_id: &str,
  ) -> Result<EncodeCollabByOid, FlowyError> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.inner.try_get_client();
    let cloned_user = self.user.clone();
    let client = try_get_client?;
    let params = object_ids
      .into_iter()
      .map(|object_id| QueryCollab::new(object_id, object_ty.clone()))
      .collect();
    let results = client.batch_get_collab(&workspace_id, params).await?;
    check_request_workspace_id_is_match(&workspace_id, &cloned_user, "batch get database object")?;
    Ok(
      results
        .0
        .into_iter()
        .flat_map(|(object_id, result)| match result {
          Success { encode_collab_v1 } => {
            match EncodedCollab::decode_from_bytes(&encode_collab_v1) {
              Ok(encode) => Some((object_id, encode)),
              Err(err) => {
                error!("Failed to decode collab: {}", err);
                None
              },
            }
          },
          Failed { error } => {
            error!("Failed to get {} update: {}", object_id, error);
            None
          },
        })
        .collect::<EncodeCollabByOid>(),
    )
  }

  async fn get_database_collab_object_snapshots(
    &self,
    _object_id: &str,
    _limit: usize,
  ) -> Result<Vec<DatabaseSnapshot>, FlowyError> {
    Ok(vec![])
  }
}

#[async_trait]
impl<T> DatabaseAIService for AFCloudDatabaseCloudServiceImpl<T>
where
  T: AFServer,
{
  async fn summary_database_row(
    &self,
    workspace_id: &str,
    _object_id: &str,
    summary_row: SummaryRowContent,
  ) -> Result<String, FlowyError> {
    let try_get_client = self.inner.try_get_client();
    let map: Map<String, Value> = summary_row
      .into_iter()
      .map(|(key, value)| (key, Value::String(value)))
      .collect();
    let params = SummarizeRowParams {
      workspace_id: workspace_id.to_string(),
      data: SummarizeRowData::Content(map),
    };
    let data = try_get_client?.summarize_row(params).await?;
    Ok(data.text)
  }

  async fn translate_database_row(
    &self,
    workspace_id: &str,
    translate_row: TranslateRowContent,
    language: &str,
  ) -> Result<TranslateRowResponse, FlowyError> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.inner.try_get_client();
    let data = TranslateRowData {
      cells: translate_row,
      language: language.to_string(),
      include_header: false,
    };

    let params = TranslateRowParams { workspace_id, data };
    let data = try_get_client?.translate_row(params).await?;
    Ok(data)
  }
}

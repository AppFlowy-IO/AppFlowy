use anyhow::Error;
use client_api::entity::ai_dto::{
  SummarizeRowData, SummarizeRowParams, TranslateRowData, TranslateRowParams,
};
use client_api::entity::QueryCollabResult::{Failed, Success};
use client_api::entity::{QueryCollab, QueryCollabParams};
use client_api::error::ErrorCode::RecordNotFound;
use collab::core::collab::DataSource;
use collab::entity::EncodedCollab;
use collab_entity::CollabType;
use serde_json::{Map, Value};
use std::sync::Arc;
use tracing::{error, instrument};

use flowy_database_pub::cloud::{
  CollabDocStateByOid, DatabaseCloudService, DatabaseSnapshot, SummaryRowContent,
  TranslateRowContent, TranslateRowResponse,
};
use lib_infra::future::FutureResult;

use crate::af_cloud::define::ServerUser;
use crate::af_cloud::impls::util::check_request_workspace_id_is_match;
use crate::af_cloud::AFServer;

pub(crate) struct AFCloudDatabaseCloudServiceImpl<T> {
  pub inner: T,
  pub user: Arc<dyn ServerUser>,
}

impl<T> DatabaseCloudService for AFCloudDatabaseCloudServiceImpl<T>
where
  T: AFServer,
{
  #[instrument(level = "debug", skip_all)]
  fn get_database_object_doc_state(
    &self,
    object_id: &str,
    collab_type: CollabType,
    workspace_id: &str,
  ) -> FutureResult<Option<Vec<u8>>, Error> {
    let workspace_id = workspace_id.to_string();
    let object_id = object_id.to_string();
    let try_get_client = self.inner.try_get_client();
    let cloned_user = self.user.clone();
    FutureResult::new(async move {
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
          Ok(Some(data.encode_collab.doc_state.to_vec()))
        },
        Err(err) => {
          if err.code == RecordNotFound {
            Ok(None)
          } else {
            Err(Error::new(err))
          }
        },
      }
    })
  }

  #[instrument(level = "debug", skip_all)]
  fn batch_get_database_object_doc_state(
    &self,
    object_ids: Vec<String>,
    object_ty: CollabType,
    workspace_id: &str,
  ) -> FutureResult<CollabDocStateByOid, Error> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.inner.try_get_client();
    let cloned_user = self.user.clone();
    FutureResult::new(async move {
      let client = try_get_client?;
      let params = object_ids
        .into_iter()
        .map(|object_id| QueryCollab::new(object_id, object_ty.clone()))
        .collect();
      let results = client.batch_get_collab(&workspace_id, params).await?;
      check_request_workspace_id_is_match(
        &workspace_id,
        &cloned_user,
        "batch get database object",
      )?;
      Ok(
        results
          .0
          .into_iter()
          .flat_map(|(object_id, result)| match result {
            Success { encode_collab_v1 } => {
              match EncodedCollab::decode_from_bytes(&encode_collab_v1) {
                Ok(encode) => Some((object_id, DataSource::DocStateV1(encode.doc_state.to_vec()))),
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
          .collect::<CollabDocStateByOid>(),
      )
    })
  }

  fn get_database_collab_object_snapshots(
    &self,
    _object_id: &str,
    _limit: usize,
  ) -> FutureResult<Vec<DatabaseSnapshot>, Error> {
    FutureResult::new(async move { Ok(vec![]) })
  }

  fn summary_database_row(
    &self,
    workspace_id: &str,
    _object_id: &str,
    summary_row: SummaryRowContent,
  ) -> FutureResult<String, Error> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.inner.try_get_client();
    FutureResult::new(async move {
      let map: Map<String, Value> = summary_row
        .into_iter()
        .map(|(key, value)| (key, Value::String(value)))
        .collect();
      let params = SummarizeRowParams {
        workspace_id,
        data: SummarizeRowData::Content(map),
      };
      let data = try_get_client?.summarize_row(params).await?;
      Ok(data.text)
    })
  }

  fn translate_database_row(
    &self,
    workspace_id: &str,
    translate_row: TranslateRowContent,
    language: &str,
  ) -> FutureResult<TranslateRowResponse, Error> {
    let language = language.to_string();
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.inner.try_get_client();
    FutureResult::new(async move {
      let data = TranslateRowData {
        cells: translate_row,
        language,
        include_header: false,
      };

      let params = TranslateRowParams { workspace_id, data };
      let data = try_get_client?.translate_row(params).await?;
      Ok(data)
    })
  }
}

use anyhow::Error;
use client_api::entity::QueryCollabResult::{Failed, Success};
use client_api::entity::{QueryCollab, QueryCollabParams};
use client_api::error::ErrorCode::RecordNotFound;
use collab::core::collab::DataSource;
use collab::entity::EncodedCollab;
use collab_entity::CollabType;
use tracing::error;

use flowy_database_pub::cloud::{CollabDocStateByOid, DatabaseCloudService, DatabaseSnapshot};
use lib_infra::future::FutureResult;

use crate::af_cloud::AFServer;

pub(crate) struct AFCloudDatabaseCloudServiceImpl<T>(pub T);

impl<T> DatabaseCloudService for AFCloudDatabaseCloudServiceImpl<T>
where
  T: AFServer,
{
  fn get_database_object_doc_state(
    &self,
    object_id: &str,
    collab_type: CollabType,
    workspace_id: &str,
  ) -> FutureResult<Option<Vec<u8>>, Error> {
    let workspace_id = workspace_id.to_string();
    let object_id = object_id.to_string();
    let try_get_client = self.0.try_get_client();
    FutureResult::new(async move {
      let params = QueryCollabParams {
        workspace_id,
        inner: QueryCollab {
          object_id,
          collab_type,
        },
      };
      match try_get_client?.get_collab(params).await {
        Ok(data) => Ok(Some(data.encode_collab.doc_state.to_vec())),
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

  fn batch_get_database_object_doc_state(
    &self,
    object_ids: Vec<String>,
    object_ty: CollabType,
    workspace_id: &str,
  ) -> FutureResult<CollabDocStateByOid, Error> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.0.try_get_client();
    FutureResult::new(async move {
      let client = try_get_client?;
      let params = object_ids
        .into_iter()
        .map(|object_id| QueryCollab {
          object_id,
          collab_type: object_ty.clone(),
        })
        .collect();
      let results = client.batch_get_collab(&workspace_id, params).await?;
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
}

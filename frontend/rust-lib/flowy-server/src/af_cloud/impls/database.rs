use anyhow::Error;
use client_api::entity::QueryCollabResult::{Failed, Success};
use client_api::entity::{BatchQueryCollabParams, QueryCollabParams};
use client_api::error::ErrorCode::RecordNotFound;
use collab_entity::CollabType;
use tracing::error;

use flowy_database_deps::cloud::{
  CollabObjectUpdate, CollabObjectUpdateByOid, DatabaseCloudService, DatabaseSnapshot,
};
use lib_infra::future::FutureResult;

use crate::af_cloud::AFServer;

pub(crate) struct AFCloudDatabaseCloudServiceImpl<T>(pub T);

impl<T> DatabaseCloudService for AFCloudDatabaseCloudServiceImpl<T>
where
  T: AFServer,
{
  fn get_collab_update(
    &self,
    object_id: &str,
    collab_type: CollabType,
  ) -> FutureResult<CollabObjectUpdate, Error> {
    let object_id = object_id.to_string();
    let try_get_client = self.0.try_get_client();
    FutureResult::new(async move {
      let params = QueryCollabParams {
        object_id,
        collab_type,
      };
      match try_get_client?.get_collab(params).await {
        Ok(data) => Ok(vec![data]),
        Err(err) => {
          if err.code == RecordNotFound {
            Ok(vec![])
          } else {
            Err(Error::new(err))
          }
        },
      }
    })
  }

  fn batch_get_collab_updates(
    &self,
    object_ids: Vec<String>,
    object_ty: CollabType,
  ) -> FutureResult<CollabObjectUpdateByOid, Error> {
    let try_get_client = self.0.try_get_client();
    FutureResult::new(async move {
      let client = try_get_client?;
      let params = BatchQueryCollabParams(
        object_ids
          .into_iter()
          .map(|object_id| QueryCollabParams {
            object_id,
            collab_type: object_ty.clone(),
          })
          .collect(),
      );
      let results = client.batch_get_collab(params).await?;
      Ok(
        results
          .0
          .into_iter()
          .flat_map(|(object_id, result)| match result {
            Success { blob } => Some((object_id, vec![blob])),
            Failed { error } => {
              error!("Failed to get {} update: {}", object_id, error);
              None
            },
          })
          .collect::<CollabObjectUpdateByOid>(),
      )
    })
  }

  fn get_collab_snapshots(
    &self,
    _object_id: &str,
    _limit: usize,
  ) -> FutureResult<Vec<DatabaseSnapshot>, Error> {
    FutureResult::new(async move { Ok(vec![]) })
  }
}

use anyhow::Error;
use client_api::entity::QueryCollabParams;
use client_api::error::ErrorCode::RecordNotFound;
use collab_define::CollabType;

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
    _object_ids: Vec<String>,
    _object_ty: CollabType,
  ) -> FutureResult<CollabObjectUpdateByOid, Error> {
    FutureResult::new(async move { Ok(CollabObjectUpdateByOid::default()) })
  }

  fn get_collab_snapshots(
    &self,
    _object_id: &str,
    _limit: usize,
  ) -> FutureResult<Vec<DatabaseSnapshot>, Error> {
    FutureResult::new(async move { Ok(vec![]) })
  }
}

use collab_plugins::cloud_storage::CollabType;
use tokio::sync::oneshot::channel;

use flowy_database2::deps::{
  CollabObjectUpdate, CollabObjectUpdateByOid, DatabaseCloudService, DatabaseSnapshot,
};
use flowy_error::{internal_error, FlowyError};
use lib_infra::future::FutureResult;

use crate::supabase::storage_impls::pooler::postgres_server::SupabaseServerService;
use crate::supabase::storage_impls::pooler::util::execute_async;
use crate::supabase::storage_impls::pooler::{
  get_latest_snapshot_from_server, BatchFetchObjectUpdateAction, FetchObjectUpdateAction,
};

pub struct SupabaseDatabaseCloudServiceImpl<T> {
  server: T,
}

impl<T> SupabaseDatabaseCloudServiceImpl<T> {
  pub fn new(server: T) -> Self {
    Self { server }
  }
}

impl<T> DatabaseCloudService for SupabaseDatabaseCloudServiceImpl<T>
where
  T: SupabaseServerService,
{
  fn get_collab_update(
    &self,
    object_id: &str,
    object_ty: CollabType,
  ) -> FutureResult<CollabObjectUpdate, FlowyError> {
    let weak_server = self.server.get_pg_server();
    let pg_mode = self.server.get_pg_mode();
    let (tx, rx) = channel();
    let database_id = object_id.to_string();
    tokio::spawn(async move {
      tx.send(
        async move {
          match weak_server {
            None => Ok(CollabObjectUpdate::default()),
            Some(weak_server) => {
              FetchObjectUpdateAction::new(database_id, object_ty, pg_mode, weak_server)
                .run()
                .await
            },
          }
        }
        .await,
      )
    });
    FutureResult::new(async { rx.await.map_err(internal_error)?.map_err(internal_error) })
  }

  fn batch_get_collab_updates(
    &self,
    object_ids: Vec<String>,
    object_ty: CollabType,
  ) -> FutureResult<CollabObjectUpdateByOid, FlowyError> {
    let weak_server = self.server.get_pg_server();
    let pg_mode = self.server.get_pg_mode();
    let (tx, rx) = channel();
    tokio::spawn(async move {
      tx.send(
        async move {
          match weak_server {
            None => Ok(CollabObjectUpdateByOid::default()),
            Some(weak_server) => {
              BatchFetchObjectUpdateAction::new(object_ids, object_ty, pg_mode, weak_server)
                .run()
                .await
            },
          }
        }
        .await,
      )
    });
    FutureResult::new(async { rx.await.map_err(internal_error)?.map_err(internal_error) })
  }

  fn get_collab_latest_snapshot(
    &self,
    object_id: &str,
  ) -> FutureResult<Option<DatabaseSnapshot>, FlowyError> {
    let object_id = object_id.to_string();
    let fut = execute_async(&self.server, move |mut pg_client, pg_mode| {
      Box::pin(async move {
        get_latest_snapshot_from_server(&object_id, pg_mode, &mut pg_client)
          .await
          .map_err(internal_error)
      })
    });
    FutureResult::new(async move {
      let snapshot = fut.await?.map(|snapshot| DatabaseSnapshot {
        snapshot_id: snapshot.snapshot_id,
        database_id: snapshot.oid,
        data: snapshot.data,
        created_at: snapshot.created_at,
      });
      Ok(snapshot)
    })
  }
}

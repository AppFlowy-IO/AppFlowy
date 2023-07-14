use tokio::sync::oneshot::channel;

use flowy_database2::deps::{
  CollabObjectUpdate, CollabObjectUpdateByOid, DatabaseCloudService, DatabaseSnapshot,
};
use flowy_error::{internal_error, FlowyError};
use lib_infra::future::FutureResult;

use crate::supabase::impls::{
  get_latest_snapshot_from_server, BatchFetchObjectUpdateAction, FetchObjectUpdateAction,
};
use crate::supabase::SupabaseServerService;

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
  fn get_collab_update(&self, object_id: &str) -> FutureResult<CollabObjectUpdate, FlowyError> {
    let weak_server = self.server.get_pg_server();
    let (tx, rx) = channel();
    let database_id = object_id.to_string();
    tokio::spawn(async move {
      tx.send(
        async move {
          match weak_server {
            None => Ok(CollabObjectUpdate::default()),
            Some(weak_server) => {
              FetchObjectUpdateAction::new(&database_id, weak_server)
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
  ) -> FutureResult<CollabObjectUpdateByOid, FlowyError> {
    let weak_server = self.server.get_pg_server();
    let (tx, rx) = channel();
    tokio::spawn(async move {
      tx.send(
        async move {
          match weak_server {
            None => Ok(CollabObjectUpdateByOid::default()),
            Some(weak_server) => {
              BatchFetchObjectUpdateAction::new(object_ids, weak_server)
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
    let weak_server = self.server.get_pg_server();
    let (tx, rx) = channel();
    let database_id = object_id.to_string();
    tokio::spawn(async move {
      tx.send(
        async move {
          match weak_server {
            None => Ok(None),
            Some(weak_server) => get_latest_snapshot_from_server(&database_id, weak_server)
              .await
              .map_err(internal_error),
          }
        }
        .await,
      )
    });
    FutureResult::new(async {
      Ok(
        rx.await
          .map_err(internal_error)??
          .map(|snapshot| DatabaseSnapshot {
            snapshot_id: snapshot.snapshot_id,
            database_id: snapshot.oid,
            data: snapshot.data,
            created_at: snapshot.created_at,
          }),
      )
    })
  }
}

use std::sync::Weak;

use tokio::sync::oneshot::channel;

use flowy_database2::deps::{
  CollabObjectUpdate, CollabObjectUpdateByOid, DatabaseCloudService, DatabaseSnapshot,
};
use flowy_error::{internal_error, ErrorCode, FlowyError, FlowyResult};
use lib_infra::future::FutureResult;

use crate::supabase::impls::{
  get_latest_snapshot_from_server, BatchFetchObjectUpdateAction, FetchObjectUpdateAction,
};
use crate::supabase::PostgresServer;

pub struct SupabaseDatabaseCloudServiceImpl {
  server: Option<Weak<PostgresServer>>,
}

impl SupabaseDatabaseCloudServiceImpl {
  pub fn new(server: Option<Weak<PostgresServer>>) -> Self {
    Self { server }
  }

  #[allow(dead_code)]
  pub fn try_get_server(&self) -> FlowyResult<Weak<PostgresServer>> {
    self.server.clone().ok_or_else(|| {
      FlowyError::new(
        ErrorCode::SupabaseSyncRequired,
        "Supabase sync is disabled, please enable it first",
      )
    })
  }
}

impl DatabaseCloudService for SupabaseDatabaseCloudServiceImpl {
  fn get_collab_update(&self, object_id: &str) -> FutureResult<CollabObjectUpdate, FlowyError> {
    let weak_server = self.server.clone();
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
    let weak_server = self.server.clone();
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
    let weak_server = self.server.clone();
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

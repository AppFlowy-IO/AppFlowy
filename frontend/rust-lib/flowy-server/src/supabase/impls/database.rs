use std::sync::Arc;

use tokio::sync::oneshot::channel;

use flowy_database2::deps::{DatabaseCloudService, DatabaseSnapshot};
use flowy_error::{internal_error, FlowyError};
use lib_infra::future::FutureResult;

use crate::supabase::impls::{get_latest_snapshot_from_server, get_updates_from_server};
use crate::supabase::PostgresServer;

pub struct SupabaseDatabaseCloudServiceImpl {
  server: Arc<PostgresServer>,
}

impl SupabaseDatabaseCloudServiceImpl {
  pub fn new(server: Arc<PostgresServer>) -> Self {
    Self { server }
  }
}

impl DatabaseCloudService for SupabaseDatabaseCloudServiceImpl {
  fn get_collab_updates(&self, object_id: &str) -> FutureResult<Vec<Vec<u8>>, FlowyError> {
    let server = Arc::downgrade(&self.server);
    let (tx, rx) = channel();
    let database_id = object_id.to_string();
    tokio::spawn(async move { tx.send(get_updates_from_server(&database_id, server).await) });
    FutureResult::new(async { rx.await.map_err(internal_error)?.map_err(internal_error) })
  }

  fn get_collab_latest_snapshot(
    &self,
    object_id: &str,
  ) -> FutureResult<Option<DatabaseSnapshot>, FlowyError> {
    let server = Arc::downgrade(&self.server);
    let (tx, rx) = channel();
    let database_id = object_id.to_string();
    tokio::spawn(
      async move { tx.send(get_latest_snapshot_from_server(&database_id, server).await) },
    );
    FutureResult::new(async {
      Ok(
        rx.await
          .map_err(internal_error)?
          .map_err(internal_error)?
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

use crate::supabase::storage_impls::restful_api::request::{
  get_latest_snapshot_from_server, BatchFetchObjectUpdateAction, FetchObjectUpdateAction,
};
use crate::supabase::storage_impls::restful_api::PostgresWrapper;
use anyhow::Error;
use collab_plugins::cloud_storage::CollabType;
use flowy_database_deps::cloud::{
  CollabObjectUpdate, CollabObjectUpdateByOid, DatabaseCloudService, DatabaseSnapshot,
};
use lib_infra::future::FutureResult;
use std::sync::Arc;
use tokio::sync::oneshot::channel;

pub struct RESTfulSupabaseDatabaseServiceImpl {
  postgrest: Arc<PostgresWrapper>,
}

impl RESTfulSupabaseDatabaseServiceImpl {
  pub fn new(postgrest: Arc<PostgresWrapper>) -> Self {
    Self { postgrest }
  }
}

impl DatabaseCloudService for RESTfulSupabaseDatabaseServiceImpl {
  fn get_collab_update(
    &self,
    object_id: &str,
    object_ty: CollabType,
  ) -> FutureResult<CollabObjectUpdate, Error> {
    let postgrest = Arc::downgrade(&self.postgrest);
    let object_id = object_id.to_string();
    let (tx, rx) = channel();
    tokio::spawn(async move {
      tx.send(
        async move {
          FetchObjectUpdateAction::new(object_id.to_string(), object_ty, postgrest)
            .run_with_fix_interval(5, 10)
            .await
        }
        .await,
      )
    });
    FutureResult::new(async { rx.await? })
  }

  fn batch_get_collab_updates(
    &self,
    object_ids: Vec<String>,
    object_ty: CollabType,
  ) -> FutureResult<CollabObjectUpdateByOid, Error> {
    let postgrest = Arc::downgrade(&self.postgrest);
    let (tx, rx) = channel();
    tokio::spawn(async move {
      tx.send(
        async move {
          BatchFetchObjectUpdateAction::new(object_ids, object_ty, postgrest)
            .run()
            .await
        }
        .await,
      )
    });
    FutureResult::new(async { rx.await? })
  }

  fn get_collab_latest_snapshot(
    &self,
    object_id: &str,
  ) -> FutureResult<Option<DatabaseSnapshot>, Error> {
    let postgrest = self.postgrest.clone();
    let object_id = object_id.to_string();
    FutureResult::new(async move {
      let snapshot = get_latest_snapshot_from_server(&object_id, postgrest)
        .await?
        .map(|snapshot| DatabaseSnapshot {
          snapshot_id: snapshot.sid,
          database_id: snapshot.oid,
          data: snapshot.blob,
          created_at: snapshot.created_at,
        });
      Ok(snapshot)
    })
  }
}

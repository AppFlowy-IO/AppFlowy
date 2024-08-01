use anyhow::Error;
use collab_entity::CollabType;
use tokio::sync::oneshot::channel;

use flowy_database_pub::cloud::{
  CollabDocStateByOid, DatabaseCloudService, DatabaseSnapshot, SummaryRowContent,
  TranslateRowContent, TranslateRowResponse,
};
use flowy_error::FlowyError;
use lib_dispatch::prelude::af_spawn;
use lib_infra::async_trait::async_trait;
use lib_infra::future::FutureResult;

use crate::supabase::api::request::{
  get_snapshots_from_server, BatchFetchObjectUpdateAction, FetchObjectUpdateAction,
};
use crate::supabase::api::SupabaseServerService;

pub struct SupabaseDatabaseServiceImpl<T> {
  server: T,
}

impl<T> SupabaseDatabaseServiceImpl<T> {
  pub fn new(server: T) -> Self {
    Self { server }
  }
}

#[async_trait]
impl<T> DatabaseCloudService for SupabaseDatabaseServiceImpl<T>
where
  T: SupabaseServerService,
{
  fn get_database_object_doc_state(
    &self,
    object_id: &str,
    collab_type: CollabType,
    _workspace_id: &str,
  ) -> FutureResult<Option<Vec<u8>>, Error> {
    let try_get_postgrest = self.server.try_get_weak_postgrest();
    let object_id = object_id.to_string();
    let (tx, rx) = channel();
    af_spawn(async move {
      tx.send(
        async move {
          let postgrest = try_get_postgrest?;
          let updates = FetchObjectUpdateAction::new(object_id.to_string(), collab_type, postgrest)
            .run_with_fix_interval(5, 10)
            .await?;
          Ok(Some(updates))
        }
        .await,
      )
    });
    FutureResult::new(async { rx.await? })
  }

  fn batch_get_database_object_doc_state(
    &self,
    object_ids: Vec<String>,
    object_ty: CollabType,
    _workspace_id: &str,
  ) -> FutureResult<CollabDocStateByOid, Error> {
    let try_get_postgrest = self.server.try_get_weak_postgrest();
    let (tx, rx) = channel();
    af_spawn(async move {
      tx.send(
        async move {
          let postgrest = try_get_postgrest?;
          BatchFetchObjectUpdateAction::new(object_ids, object_ty, postgrest)
            .run()
            .await
        }
        .await,
      )
    });
    FutureResult::new(async { rx.await? })
  }

  fn get_database_collab_object_snapshots(
    &self,
    object_id: &str,
    limit: usize,
  ) -> FutureResult<Vec<DatabaseSnapshot>, Error> {
    let try_get_postgrest = self.server.try_get_postgrest();
    let object_id = object_id.to_string();
    FutureResult::new(async move {
      let postgrest = try_get_postgrest?;
      let snapshots = get_snapshots_from_server(&object_id, postgrest, limit)
        .await?
        .into_iter()
        .map(|snapshot| DatabaseSnapshot {
          snapshot_id: snapshot.sid,
          database_id: snapshot.oid,
          data: snapshot.blob,
          created_at: snapshot.created_at,
        })
        .collect::<Vec<_>>();

      Ok(snapshots)
    })
  }

  async fn summary_database_row(
    &self,
    _workspace_id: &str,
    _object_id: &str,
    _summary_row: SummaryRowContent,
  ) -> Result<String, FlowyError> {
    Ok("".to_string())
  }

  async fn translate_database_row(
    &self,
    _workspace_id: &str,
    _translate_row: TranslateRowContent,
    _language: &str,
  ) -> Result<TranslateRowResponse, FlowyError> {
    Ok(TranslateRowResponse::default())
  }
}

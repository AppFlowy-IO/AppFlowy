use anyhow::Error;
use chrono::{DateTime, Utc};
use collab::core::origin::CollabOrigin;
use collab_plugins::cloud_storage::CollabType;
use deadpool_postgres::GenericClient;
use futures_util::{pin_mut, StreamExt};
use tokio::sync::oneshot::channel;
use uuid::Uuid;

use flowy_error::{ErrorCode, FlowyError};
use flowy_folder_deps::cloud::{
  gen_workspace_id, Folder, FolderCloudService, FolderData, FolderSnapshot, Workspace,
};
use lib_infra::future::FutureResult;

use crate::supabase::storage_impls::pooler::postgres_server::SupabaseServerService;
use crate::supabase::storage_impls::pooler::sql_builder::{InsertSqlBuilder, SelectSqlBuilder};
use crate::supabase::storage_impls::pooler::util::execute_async;
use crate::supabase::storage_impls::pooler::{
  get_latest_snapshot_from_server, get_updates_from_server, prepare_cached,
  FetchObjectUpdateAction, PostgresObject,
};
use crate::supabase::storage_impls::OWNER_USER_UID;
use crate::supabase::PgPoolMode;

pub(crate) const WORKSPACE_TABLE: &str = "af_workspace";
pub(crate) const LATEST_WORKSPACE_ID: &str = "latest_workspace_id";
pub(crate) const WORKSPACE_ID: &str = "workspace_id";
pub(crate) const WORKSPACE_NAME: &str = "workspace_name";
pub(crate) const CREATED_AT: &str = "created_at";

pub struct SupabaseFolderCloudServiceImpl<T> {
  server: T,
}

impl<T> SupabaseFolderCloudServiceImpl<T> {
  pub fn new(server: T) -> Self {
    Self { server }
  }
}

impl<T> FolderCloudService for SupabaseFolderCloudServiceImpl<T>
where
  T: SupabaseServerService,
{
  fn create_workspace(&self, uid: i64, name: &str) -> FutureResult<Workspace, Error> {
    let name = name.to_string();
    execute_async(&self.server, move |mut pg_client, pg_mode| {
      Box::pin(async move { create_workspace(&mut pg_client, &pg_mode, uid, &name).await })
    })
  }

  fn get_folder_data(&self, workspace_id: &str) -> FutureResult<Option<FolderData>, Error> {
    let workspace_id = workspace_id.to_string();
    execute_async(&self.server, move |mut pg_client, pg_mode| {
      Box::pin(async move {
        let folder_data =
          get_updates_from_server(&workspace_id, &CollabType::Folder, &pg_mode, &mut pg_client)
            .await
            .map(|updates| {
              let folder =
                Folder::from_collab_raw_data(CollabOrigin::Empty, updates, &workspace_id, vec![])
                  .ok()?;
              folder.get_folder_data()
            })?;
        Ok(folder_data)
      })
    })
  }

  fn get_folder_latest_snapshot(
    &self,
    workspace_id: &str,
  ) -> FutureResult<Option<FolderSnapshot>, Error> {
    let workspace_id = workspace_id.to_string();
    let fut = execute_async(&self.server, move |mut pg_client, pg_mode| {
      Box::pin(async move {
        let snapshot =
          get_latest_snapshot_from_server(&workspace_id, pg_mode, &mut pg_client).await?;
        Ok(snapshot)
      })
    });
    FutureResult::new(async move {
      let snapshot = fut.await?.map(|snapshot| FolderSnapshot {
        snapshot_id: snapshot.sid,
        database_id: snapshot.oid,
        data: snapshot.blob,
        created_at: snapshot.created_at,
      });
      Ok(snapshot)
    })
  }

  fn get_folder_updates(&self, workspace_id: &str, _uid: i64) -> FutureResult<Vec<Vec<u8>>, Error> {
    let weak_server = self.server.get_pg_server();
    let pg_mode = self.server.get_pg_mode();
    let (tx, rx) = channel();
    let workspace_id = workspace_id.to_string();
    tokio::spawn(async move {
      tx.send(
        async move {
          match weak_server {
            None => Ok(vec![]),
            Some(weak_server) => {
              let action = FetchObjectUpdateAction::new(
                workspace_id,
                CollabType::Folder,
                pg_mode,
                weak_server,
              );
              action.run_with_fix_interval(5, 10).await
            },
          }
        }
        .await,
      )
    });
    FutureResult::new(async { rx.await? })
  }

  fn service_name(&self) -> String {
    "Supabase".to_string()
  }
}

async fn create_workspace(
  client: &mut PostgresObject,
  pg_mode: &PgPoolMode,
  uid: i64,
  name: &str,
) -> Result<Workspace, Error> {
  let new_workspace_id = gen_workspace_id();

  // Create workspace
  let (sql, params) = InsertSqlBuilder::new(WORKSPACE_TABLE)
    .value(OWNER_USER_UID, uid)
    .value(WORKSPACE_ID, new_workspace_id)
    .value(WORKSPACE_NAME, name.to_string())
    .build();
  let txn = client.transaction().await?;
  let stmt = prepare_cached(pg_mode, sql, &txn).await?;
  txn.execute_raw(stmt.as_ref(), params).await?;

  // Read the workspace
  let (sql, params) = SelectSqlBuilder::new(WORKSPACE_TABLE)
    .column(WORKSPACE_ID)
    .column(WORKSPACE_NAME)
    .column(CREATED_AT)
    .where_clause(WORKSPACE_ID, new_workspace_id)
    .build();
  let stmt = prepare_cached(pg_mode, sql, &txn).await?;
  let rows = Box::pin(txn.query_raw(stmt.as_ref(), params).await?);
  pin_mut!(rows);
  txn.commit().await?;

  if let Some(Ok(row)) = rows.next().await {
    let created_at = row
      .try_get::<&str, DateTime<Utc>>(CREATED_AT)
      .unwrap_or_default();
    let workspace_id: Uuid = row.get(WORKSPACE_ID);

    Ok(Workspace {
      id: workspace_id.to_string(),
      name: row.get(WORKSPACE_NAME),
      child_views: Default::default(),
      created_at: created_at.timestamp(),
    })
  } else {
    Err(FlowyError::new(ErrorCode::PgDatabaseError, "Create workspace failed").into())
  }
}

use std::sync::Arc;

use chrono::{DateTime, Utc};
use futures_util::{pin_mut, StreamExt};
use tokio::sync::oneshot::channel;
use uuid::Uuid;

use crate::supabase::impls::{get_latest_snapshot_from_server, get_updates_from_server};
use flowy_error::{internal_error, ErrorCode, FlowyError};
use flowy_folder2::deps::{FolderCloudService, FolderSnapshot, Workspace};
use lib_infra::future::FutureResult;

use crate::supabase::pg_db::PostgresObject;
use crate::supabase::sql_builder::{InsertSqlBuilder, SelectSqlBuilder};
use crate::supabase::PostgresServer;

pub(crate) const WORKSPACE_TABLE: &str = "af_workspace";
pub(crate) const WORKSPACE_ID: &str = "workspace_id";
const WORKSPACE_NAME: &str = "workspace_name";
const CREATED_AT: &str = "created_at";

pub(crate) struct SupabaseFolderCloudServiceImpl {
  server: Arc<PostgresServer>,
}

impl SupabaseFolderCloudServiceImpl {
  pub fn new(server: Arc<PostgresServer>) -> Self {
    Self { server }
  }
}

impl FolderCloudService for SupabaseFolderCloudServiceImpl {
  fn create_workspace(&self, uid: i64, name: &str) -> FutureResult<Workspace, FlowyError> {
    let server = self.server.clone();
    let (tx, rx) = channel();
    let name = name.to_string();
    tokio::spawn(async move {
      tx.send(
        async move {
          let client = server.get_pg_client().await.recv().await?;
          create_workspace(&client, uid, &name).await
        }
        .await,
      )
    });
    FutureResult::new(async { rx.await.map_err(internal_error)? })
  }

  fn get_folder_latest_snapshot(
    &self,
    workspace_id: &str,
  ) -> FutureResult<Option<FolderSnapshot>, FlowyError> {
    let server = Arc::downgrade(&self.server);
    let workspace_id = workspace_id.to_string();
    let (tx, rx) = channel();
    tokio::spawn(
      async move { tx.send(get_latest_snapshot_from_server(&workspace_id, server).await) },
    );
    FutureResult::new(async {
      Ok(
        rx.await
          .map_err(internal_error)?
          .map_err(internal_error)?
          .map(|snapshot| FolderSnapshot {
            snapshot_id: snapshot.snapshot_id,
            database_id: snapshot.oid,
            data: snapshot.data,
            created_at: snapshot.created_at,
          }),
      )
    })
  }

  fn get_folder_updates(&self, workspace_id: &str) -> FutureResult<Vec<Vec<u8>>, FlowyError> {
    let server = Arc::downgrade(&self.server);
    let (tx, rx) = channel();
    let workspace_id = workspace_id.to_string();
    tokio::spawn(async move { tx.send(get_updates_from_server(&workspace_id, server).await) });
    FutureResult::new(async { rx.await.map_err(internal_error)?.map_err(internal_error) })
  }
}

async fn create_workspace(
  client: &PostgresObject,
  uid: i64,
  name: &str,
) -> Result<Workspace, FlowyError> {
  let new_workspace_id = Uuid::new_v4();

  // Create workspace
  let (sql, params) = InsertSqlBuilder::new(WORKSPACE_TABLE)
    .value("uid", uid)
    .value(WORKSPACE_ID, new_workspace_id)
    .value(WORKSPACE_NAME, name.to_string())
    .build();
  let stmt = client
    .prepare_cached(&sql)
    .await
    .map_err(|e| FlowyError::new(ErrorCode::PgDatabaseError, e))?;
  client
    .execute_raw(&stmt, params)
    .await
    .map_err(|e| FlowyError::new(ErrorCode::PgDatabaseError, e))?;

  // Read the workspace
  let (sql, params) = SelectSqlBuilder::new(WORKSPACE_TABLE)
    .column(WORKSPACE_ID)
    .column(WORKSPACE_NAME)
    .column(CREATED_AT)
    .where_clause(WORKSPACE_ID, new_workspace_id)
    .build();
  let stmt = client
    .prepare_cached(&sql)
    .await
    .map_err(|e| FlowyError::new(ErrorCode::PgDatabaseError, e))?;

  let rows = Box::pin(
    client
      .query_raw(&stmt, params)
      .await
      .map_err(|e| FlowyError::new(ErrorCode::PgDatabaseError, e))?,
  );
  pin_mut!(rows);

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
    Err(FlowyError::new(
      ErrorCode::PgDatabaseError,
      "Create workspace failed",
    ))
  }
}

#[cfg(test)]
mod tests {
  use std::collections::HashMap;
  use std::sync::Arc;

  use uuid::Uuid;

  use flowy_folder2::deps::FolderCloudService;
  use flowy_user::event_map::UserAuthService;
  use lib_infra::box_any::BoxAny;

  use crate::supabase::impls::folder::SupabaseFolderCloudServiceImpl;
  use crate::supabase::impls::SupabaseUserAuthServiceImpl;
  use crate::supabase::{PostgresConfiguration, PostgresServer};

  #[tokio::test]
  async fn create_user_workspace() {
    if dotenv::from_filename("./.env.workspace.test").is_err() {
      return;
    }
    let server = Arc::new(PostgresServer::new(
      PostgresConfiguration::from_env().unwrap(),
    ));
    let user_service = SupabaseUserAuthServiceImpl::new(server.clone());

    // create user
    let mut params = HashMap::new();
    params.insert("uuid".to_string(), Uuid::new_v4().to_string());
    let user = user_service.sign_up(BoxAny::new(params)).await.unwrap();

    // create workspace
    let folder_service = SupabaseFolderCloudServiceImpl::new(server);
    let workspace = folder_service
      .create_workspace(user.user_id, "my test workspace")
      .await
      .unwrap();

    assert_eq!(workspace.name, "my test workspace");
  }
}

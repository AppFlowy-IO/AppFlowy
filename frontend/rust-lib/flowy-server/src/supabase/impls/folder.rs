use std::sync::Arc;

use chrono::{DateTime, Utc};
use futures_util::{pin_mut, StreamExt};
use tokio::sync::oneshot::channel;
use uuid::Uuid;

use flowy_error::{internal_error, ErrorCode, FlowyError};
use flowy_folder2::deps::{FolderCloudService, Workspace};
use lib_infra::future::FutureResult;

use crate::supabase::pg_db::{PostgresClient, SelectSqlBuilder};
use crate::supabase::sql_builder::InsertSqlBuilder;
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
          let client = server.pg_client().await?;
          create_workspace(&client, uid, &name).await
        }
        .await,
      )
    });
    FutureResult::new(async { rx.await.map_err(internal_error)? })
  }
}

async fn create_workspace(
  client: &Arc<PostgresClient>,
  uid: i64,
  name: &str,
) -> Result<Workspace, FlowyError> {
  let new_workspace_id = Uuid::new_v4();
  let (sql, params) = InsertSqlBuilder::new(WORKSPACE_TABLE)
    .value("uid", uid)
    .value(WORKSPACE_ID, new_workspace_id)
    .value(WORKSPACE_NAME, name.to_string())
    .build();

  client
    .execute_raw(&sql, params)
    .await
    .map_err(|e| FlowyError::new(ErrorCode::PgDatabaseError, e))?;

  let (sql, params) = SelectSqlBuilder::new(WORKSPACE_TABLE)
    .column(WORKSPACE_ID)
    .column(WORKSPACE_NAME)
    .column(CREATED_AT)
    .where_clause(WORKSPACE_ID, new_workspace_id)
    .build();

  let rows = Box::pin(
    client
      .query_raw(&sql, params)
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
  use crate::supabase::impls::PostgrestUserAuthServiceImpl;
  use crate::supabase::PostgresServer;

  #[tokio::test]
  async fn create_user_workspace() {
    if dotenv::from_filename("./.env.workspace.test").is_err() {
      return;
    }
    let server = Arc::new(PostgresServer::new());
    let user_service = PostgrestUserAuthServiceImpl::new(server.clone());

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

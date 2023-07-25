use appflowy_integrate::CollabType;
use chrono::{DateTime, Utc};
use collab_folder::core::{CollabOrigin, Folder};
use deadpool_postgres::GenericClient;
use futures_util::{pin_mut, StreamExt};
use tokio::sync::oneshot::channel;
use uuid::Uuid;

use flowy_error::{internal_error, ErrorCode, FlowyError, FlowyResult};
use flowy_folder2::deps::{FolderCloudService, FolderData, FolderSnapshot, Workspace};
use lib_infra::future::FutureResult;

use crate::supabase::collab_storage_impls::pooler::util::execute_async;
use crate::supabase::collab_storage_impls::pooler::{
  get_latest_snapshot_from_server, get_updates_from_server, FetchObjectUpdateAction,
};
use crate::supabase::postgres_db::{prepare_cached, PostgresObject};
use crate::supabase::sql_builder::{InsertSqlBuilder, SelectSqlBuilder};
use crate::supabase::{PgPoolMode, SupabaseServerService};

pub(crate) const WORKSPACE_TABLE: &str = "af_workspace";
pub(crate) const LATEST_WORKSPACE_ID: &str = "latest_workspace_id";
const WORKSPACE_NAME: &str = "workspace_name";
const CREATED_AT: &str = "created_at";

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
  fn create_workspace(&self, uid: i64, name: &str) -> FutureResult<Workspace, FlowyError> {
    let name = name.to_string();
    execute_async(&self.server, move |mut pg_client, pg_mode| {
      Box::pin(async move { create_workspace(&mut pg_client, &pg_mode, uid, &name).await })
    })
  }

  fn add_member_to_workspace(
    &self,
    email: &str,
    workspace_id: &str,
  ) -> FutureResult<(), FlowyError> {
    let email = email.to_string();
    let workspace_id = workspace_id.to_string();
    execute_async(&self.server, move |pg_client, pg_mode| {
      Box::pin(
        async move { add_member_to_workspace(&pg_client, &pg_mode, &email, &workspace_id).await },
      )
    })
  }

  fn remove_member_from_workspace(
    &self,
    _email: &str,
    _workspace_id: &str,
  ) -> FutureResult<(), FlowyError> {
    todo!()
  }

  fn get_folder_data(&self, workspace_id: &str) -> FutureResult<Option<FolderData>, FlowyError> {
    let workspace_id = workspace_id.to_string();
    execute_async(&self.server, move |mut pg_client, pg_mode| {
      Box::pin(async move {
        get_updates_from_server(
          &workspace_id,
          &CollabType::Document,
          &pg_mode,
          &mut pg_client,
        )
        .await
        .map(|updates| {
          let folder =
            Folder::from_collab_raw_data(CollabOrigin::Empty, updates, &workspace_id, vec![])
              .ok()?;
          folder.get_folder_data()
        })
        .map_err(internal_error)
      })
    })
  }

  fn get_folder_latest_snapshot(
    &self,
    workspace_id: &str,
  ) -> FutureResult<Option<FolderSnapshot>, FlowyError> {
    let workspace_id = workspace_id.to_string();
    let fut = execute_async(&self.server, move |mut pg_client, pg_mode| {
      Box::pin(async move {
        get_latest_snapshot_from_server(&workspace_id, pg_mode, &mut pg_client)
          .await
          .map_err(internal_error)
      })
    });
    FutureResult::new(async move {
      let snapshot = fut.await?.map(|snapshot| FolderSnapshot {
        snapshot_id: snapshot.snapshot_id,
        database_id: snapshot.oid,
        data: snapshot.data,
        created_at: snapshot.created_at,
      });
      Ok(snapshot)
    })
  }

  fn get_folder_updates(
    &self,
    workspace_id: &str,
    _uid: i64,
  ) -> FutureResult<Vec<Vec<u8>>, FlowyError> {
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
    FutureResult::new(async { rx.await.map_err(internal_error)?.map_err(internal_error) })
  }

  fn service_name(&self) -> String {
    "Supabase".to_string()
  }
}

async fn add_member_to_workspace(
  _client: &PostgresObject,
  _pg_mode: &PgPoolMode,
  _email: &str,
  _workspace_id: &str,
) -> FlowyResult<()> {
  Ok(())
}

async fn create_workspace(
  client: &mut PostgresObject,
  pg_mode: &PgPoolMode,
  uid: i64,
  name: &str,
) -> Result<Workspace, FlowyError> {
  let new_workspace_id = Uuid::new_v4();

  // Create workspace
  let (sql, params) = InsertSqlBuilder::new(WORKSPACE_TABLE)
    .value("uid", uid)
    .value(LATEST_WORKSPACE_ID, new_workspace_id)
    .value(WORKSPACE_NAME, name.to_string())
    .build();
  let txn = client.transaction().await.map_err(internal_error)?;
  let stmt = prepare_cached(pg_mode, sql, &txn)
    .await
    .map_err(|e| FlowyError::new(ErrorCode::PgDatabaseError, e))?;
  txn
    .execute_raw(stmt.as_ref(), params)
    .await
    .map_err(|e| FlowyError::new(ErrorCode::PgDatabaseError, e))?;

  // Read the workspace
  let (sql, params) = SelectSqlBuilder::new(WORKSPACE_TABLE)
    .column(LATEST_WORKSPACE_ID)
    .column(WORKSPACE_NAME)
    .column(CREATED_AT)
    .where_clause(LATEST_WORKSPACE_ID, new_workspace_id)
    .build();
  let stmt = prepare_cached(pg_mode, sql, &txn)
    .await
    .map_err(|e| FlowyError::new(ErrorCode::PgDatabaseError, e))?;

  let rows = Box::pin(
    txn
      .query_raw(stmt.as_ref(), params)
      .await
      .map_err(|e| FlowyError::new(ErrorCode::PgDatabaseError, e))?,
  );
  pin_mut!(rows);
  txn.commit().await.map_err(internal_error)?;

  if let Some(Ok(row)) = rows.next().await {
    let created_at = row
      .try_get::<&str, DateTime<Utc>>(CREATED_AT)
      .unwrap_or_default();
    let workspace_id: Uuid = row.get(LATEST_WORKSPACE_ID);

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

  use parking_lot::RwLock;
  use uuid::Uuid;

  use flowy_folder2::deps::FolderCloudService;
  use flowy_server_config::supabase_config::PostgresConfiguration;
  use flowy_user::event_map::UserService;
  use lib_infra::box_any::BoxAny;

  use crate::supabase::collab_storage_impls::pooler::folder::SupabaseFolderCloudServiceImpl;
  use crate::supabase::collab_storage_impls::pooler::SupabaseUserAuthServiceImpl;
  use crate::supabase::{PgPoolMode, PostgresServer, SupabaseServerServiceImpl};

  #[tokio::test]
  async fn create_user_workspace() {
    if dotenv::from_filename("./.env.workspace.test").is_err() {
      return;
    }
    let server = Arc::new(PostgresServer::new(
      PgPoolMode::default(),
      PostgresConfiguration::from_env().unwrap(),
    ));
    let weak_server = SupabaseServerServiceImpl(Arc::new(RwLock::new(Some(server.clone()))));
    let user_service = SupabaseUserAuthServiceImpl::new(weak_server.clone());

    // create user
    let mut params = HashMap::new();
    params.insert("uuid".to_string(), Uuid::new_v4().to_string());
    let user = user_service.sign_up(BoxAny::new(params)).await.unwrap();

    // create workspace
    let folder_service = SupabaseFolderCloudServiceImpl::new(weak_server);
    let workspace = folder_service
      .create_workspace(user.user_id, "my test workspace")
      .await
      .unwrap();

    assert_eq!(workspace.name, "my test workspace");
  }
}

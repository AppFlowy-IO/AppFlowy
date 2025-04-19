use crate::entities::{AuthType, UserWorkspace};
use chrono::{TimeZone, Utc};
use flowy_error::{FlowyError, FlowyResult};
use flowy_sqlite::schema::user_workspace_table;
use flowy_sqlite::DBConnection;
use flowy_sqlite::{prelude::*, ExpressionMethods, RunQueryDsl, SqliteConnection};
use tracing::{info, warn};

#[derive(Clone, Default, Queryable, Identifiable, Insertable)]
#[diesel(table_name = user_workspace_table)]
pub struct UserWorkspaceTable {
  pub id: String,
  pub name: String,
  pub uid: i64,
  pub created_at: i64,
  pub database_storage_id: String,
  pub icon: String,
  pub member_count: i64,
  pub role: Option<i32>,
  pub auth_type: i32,
}

#[derive(AsChangeset, Identifiable, Default, Debug)]
#[diesel(table_name = user_workspace_table)]
pub struct UserWorkspaceChangeset {
  pub id: String,
  pub name: Option<String>,
  pub icon: Option<String>,
}

impl UserWorkspaceTable {
  pub fn from_workspace(
    uid: i64,
    workspace: &UserWorkspace,
    auth_type: AuthType,
  ) -> Result<Self, FlowyError> {
    if workspace.id.is_empty() {
      return Err(FlowyError::invalid_data().with_context("The id is empty"));
    }
    if workspace.workspace_database_id.is_empty() {
      return Err(FlowyError::invalid_data().with_context("The database storage id is empty"));
    }

    Ok(Self {
      id: workspace.id.clone(),
      name: workspace.name.clone(),
      uid,
      created_at: workspace.created_at.timestamp(),
      database_storage_id: workspace.workspace_database_id.clone(),
      icon: workspace.icon.clone(),
      member_count: workspace.member_count,
      role: workspace.role.clone().map(|v| v as i32),
      auth_type: auth_type as i32,
    })
  }
}

pub fn select_user_workspace(
  workspace_id: &str,
  mut conn: DBConnection,
) -> FlowyResult<UserWorkspaceTable> {
  let row = user_workspace_table::dsl::user_workspace_table
    .filter(user_workspace_table::id.eq(workspace_id))
    .first::<UserWorkspaceTable>(&mut *conn)?;
  Ok(row)
}

pub fn select_all_user_workspace(
  user_id: i64,
  mut conn: DBConnection,
) -> Result<Vec<UserWorkspace>, FlowyError> {
  let rows = user_workspace_table::dsl::user_workspace_table
    .filter(user_workspace_table::uid.eq(user_id))
    .load::<UserWorkspaceTable>(&mut *conn)?;
  Ok(rows.into_iter().map(UserWorkspace::from).collect())
}

pub fn update_user_workspace(
  mut conn: DBConnection,
  changeset: UserWorkspaceChangeset,
) -> Result<(), FlowyError> {
  diesel::update(user_workspace_table::dsl::user_workspace_table)
    .filter(user_workspace_table::id.eq(changeset.id.clone()))
    .set(changeset)
    .execute(&mut conn)?;

  Ok(())
}

pub fn upsert_user_workspace(
  uid: i64,
  auth_type: AuthType,
  user_workspace: UserWorkspace,
  conn: &mut SqliteConnection,
) -> Result<(), FlowyError> {
  let row = UserWorkspaceTable::from_workspace(uid, &user_workspace, auth_type)?;
  diesel::insert_into(user_workspace_table::table)
    .values(row.clone())
    .on_conflict(user_workspace_table::id)
    .do_update()
    .set((
      user_workspace_table::name.eq(row.name),
      user_workspace_table::uid.eq(row.uid),
      user_workspace_table::created_at.eq(row.created_at),
      user_workspace_table::database_storage_id.eq(row.database_storage_id),
      user_workspace_table::icon.eq(row.icon),
      user_workspace_table::member_count.eq(row.member_count),
      user_workspace_table::role.eq(row.role),
      user_workspace_table::auth_type.eq(row.auth_type),
    ))
    .execute(conn)?;

  Ok(())
}

pub fn delete_user_workspace(mut conn: DBConnection, workspace_id: &str) -> FlowyResult<()> {
  let n = conn.immediate_transaction(|conn| {
    let rows_affected: usize =
      diesel::delete(user_workspace_table::table.filter(user_workspace_table::id.eq(workspace_id)))
        .execute(conn)?;
    Ok::<usize, FlowyError>(rows_affected)
  })?;

  if n != 1 {
    warn!("expected to delete 1 row, but deleted {} rows", n);
  }
  Ok(())
}

impl From<UserWorkspaceTable> for UserWorkspace {
  fn from(value: UserWorkspaceTable) -> Self {
    Self {
      id: value.id,
      name: value.name,
      created_at: Utc
        .timestamp_opt(value.created_at, 0)
        .single()
        .unwrap_or_default(),
      workspace_database_id: value.database_storage_id,
      icon: value.icon,
      member_count: value.member_count,
      role: value.role.map(|v| v.into()),
    }
  }
}

/// Delete all user workspaces for the given user and auth type.
pub fn delete_user_all_workspace(
  uid: i64,
  auth_type: AuthType,
  conn: &mut SqliteConnection,
) -> FlowyResult<()> {
  let n = diesel::delete(
    user_workspace_table::dsl::user_workspace_table
      .filter(user_workspace_table::uid.eq(uid))
      .filter(user_workspace_table::auth_type.eq(auth_type as i32)),
  )
  .execute(conn)?;
  info!(
    "Delete {} workspaces for user {} and auth type {:?}",
    n, uid, auth_type
  );
  Ok(())
}

/// Delete all user workspaces for the given user and auth type, then insert the provided user workspaces.
pub fn delete_all_then_insert_user_workspaces(
  uid: i64,
  mut conn: DBConnection,
  auth_type: AuthType,
  user_workspaces: &[UserWorkspace],
) -> FlowyResult<()> {
  conn.immediate_transaction(|conn| {
    delete_user_all_workspace(uid, auth_type, conn)?;

    info!(
      "Insert {} workspaces for user {} and auth type {:?}",
      user_workspaces.len(),
      uid,
      auth_type
    );
    for user_workspace in user_workspaces {
      upsert_user_workspace(uid, auth_type, user_workspace.clone(), conn)?;
    }
    Ok::<(), FlowyError>(())
  })
}

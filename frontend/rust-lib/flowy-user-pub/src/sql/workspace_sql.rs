use crate::entities::{AuthType, UserWorkspace};
use chrono::{TimeZone, Utc};
use flowy_error::{FlowyError, FlowyResult};
use flowy_sqlite::schema::user_workspace_table;
use flowy_sqlite::schema::user_workspace_table::dsl;
use flowy_sqlite::DBConnection;
use flowy_sqlite::{prelude::*, ExpressionMethods, RunQueryDsl, SqliteConnection};
use std::collections::{HashMap, HashSet};
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
  pub workspace_type: i32,
}

#[derive(AsChangeset, Identifiable, Default, Debug)]
#[diesel(table_name = user_workspace_table)]
pub struct UserWorkspaceChangeset {
  pub id: String,
  pub name: Option<String>,
  pub icon: Option<String>,
  pub role: Option<i32>,
  pub member_count: Option<i64>,
}

impl UserWorkspaceChangeset {
  pub fn has_changes(&self) -> bool {
    self.name.is_some() || self.icon.is_some() || self.role.is_some() || self.member_count.is_some()
  }
  pub fn from_version(old: &UserWorkspace, new: &UserWorkspace) -> Self {
    let mut changeset = Self {
      id: new.id.clone(),
      name: None,
      icon: None,
      role: None,
      member_count: None,
    };

    if old.name != new.name {
      changeset.name = Some(new.name.clone());
    }
    if old.icon != new.icon {
      changeset.icon = Some(new.icon.clone());
    }
    if old.role != new.role {
      changeset.role = new.role.map(|v| v as i32);
    }
    if old.member_count != new.member_count {
      changeset.member_count = Some(new.member_count);
    }

    changeset
  }
}

impl UserWorkspaceTable {
  pub fn from_workspace(
    uid_val: i64,
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
      uid: uid_val,
      created_at: workspace.created_at.timestamp(),
      database_storage_id: workspace.workspace_database_id.clone(),
      icon: workspace.icon.clone(),
      member_count: workspace.member_count,
      role: workspace.role.map(|v| v as i32),
      workspace_type: auth_type as i32,
    })
  }
}

pub fn select_user_workspace(
  workspace_id: &str,
  conn: &mut SqliteConnection,
) -> FlowyResult<UserWorkspaceTable> {
  let row = dsl::user_workspace_table
    .filter(user_workspace_table::id.eq(workspace_id))
    .first::<UserWorkspaceTable>(conn)?;
  Ok(row)
}

pub fn select_all_user_workspace(
  uid: i64,
  conn: &mut SqliteConnection,
) -> Result<Vec<UserWorkspace>, FlowyError> {
  let rows = user_workspace_table::dsl::user_workspace_table
    .filter(user_workspace_table::uid.eq(uid))
    .order(user_workspace_table::created_at.desc())
    .load::<UserWorkspaceTable>(conn)?;
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
    dsl::user_workspace_table
      .filter(user_workspace_table::uid.eq(uid))
      .filter(user_workspace_table::workspace_type.eq(auth_type as i32)),
  )
  .execute(conn)?;
  info!(
    "Delete {} workspaces for user {} and auth type {:?}",
    n, uid, auth_type
  );
  Ok(())
}

#[derive(Debug)]
pub enum WorkspaceChange {
  Inserted(String),
  Updated(String),
}

pub fn upsert_user_workspace(
  uid_val: i64,
  auth_type: AuthType,
  user_workspace: UserWorkspace,
  conn: &mut SqliteConnection,
) -> Result<usize, FlowyError> {
  let row = UserWorkspaceTable::from_workspace(uid_val, &user_workspace, auth_type)?;
  let n = insert_into(user_workspace_table::table)
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
    ))
    .execute(conn)?;

  Ok(n)
}

pub fn sync_user_workspaces_with_diff(
  uid_val: i64,
  auth_type: AuthType,
  user_workspaces: &[UserWorkspace],
  conn: &mut SqliteConnection,
) -> FlowyResult<Vec<WorkspaceChange>> {
  let diff = conn.immediate_transaction(|conn| {
    // 1) Load all existing workspaces into a map
    let existing_rows: Vec<UserWorkspaceTable> = dsl::user_workspace_table
      .filter(user_workspace_table::uid.eq(uid_val))
      .filter(user_workspace_table::workspace_type.eq(auth_type as i32))
      .load(conn)?;
    let mut existing_map: HashMap<String, UserWorkspaceTable> = existing_rows
      .into_iter()
      .map(|r| (r.id.clone(), r))
      .collect();

    // 2) Build incoming ID set and delete any stale ones
    let incoming_ids: HashSet<String> = user_workspaces.iter().map(|uw| uw.id.clone()).collect();
    let to_delete: Vec<String> = existing_map
      .keys()
      .filter(|id| !incoming_ids.contains(*id))
      .cloned()
      .collect();

    if !to_delete.is_empty() {
      diesel::delete(dsl::user_workspace_table.filter(user_workspace_table::id.eq_any(&to_delete)))
        .execute(conn)?;
    }

    // 3) For each incoming workspace, either INSERT or UPDATE if changed
    let mut diffs = Vec::new();
    for uw in user_workspaces {
      match existing_map.remove(&uw.id) {
        None => {
          // new workspace → insert
          let new_row = UserWorkspaceTable::from_workspace(uid_val, uw, auth_type)?;
          diesel::insert_into(user_workspace_table::table)
            .values(new_row)
            .execute(conn)?;
          diffs.push(WorkspaceChange::Inserted(uw.id.clone()));
        },

        Some(old) => {
          let changes = UserWorkspaceChangeset::from_version(&UserWorkspace::from(old), uw);
          if changes.has_changes() {
            diesel::update(dsl::user_workspace_table.find(&uw.id))
              .set(&changes)
              .execute(conn)?;
            diffs.push(WorkspaceChange::Updated(uw.id.clone()));
          }
        },
      }
    }

    Ok::<_, FlowyError>(diffs)
  })?;
  Ok(diff)
}

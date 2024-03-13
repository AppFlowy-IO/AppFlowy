use chrono::{TimeZone, Utc};
use diesel::{RunQueryDsl, SqliteConnection};
use flowy_error::FlowyError;
use flowy_sqlite::schema::user_workspace_table;
use flowy_sqlite::DBConnection;
use flowy_sqlite::{query_dsl::*, ExpressionMethods};
use flowy_user_pub::entities::UserWorkspace;
use std::convert::TryFrom;

#[derive(Clone, Default, Queryable, Identifiable, Insertable)]
#[diesel(table_name = user_workspace_table)]
pub struct UserWorkspaceTable {
  pub id: String,
  pub name: String,
  pub uid: i64,
  pub created_at: i64,
  pub database_storage_id: String,
  pub icon: String,
}

pub fn get_user_workspace_op(workspace_id: &str, mut conn: DBConnection) -> Option<UserWorkspace> {
  user_workspace_table::dsl::user_workspace_table
    .filter(user_workspace_table::id.eq(workspace_id))
    .first::<UserWorkspaceTable>(&mut *conn)
    .ok()
    .map(UserWorkspace::from)
}

pub fn get_all_user_workspace_op(
  user_id: i64,
  mut conn: DBConnection,
) -> Result<Vec<UserWorkspace>, FlowyError> {
  let rows = user_workspace_table::dsl::user_workspace_table
    .filter(user_workspace_table::uid.eq(user_id))
    .load::<UserWorkspaceTable>(&mut *conn)?;
  Ok(rows.into_iter().map(UserWorkspace::from).collect())
}

/// Remove all existing workspaces for given user and insert the new ones.
///
#[allow(dead_code)]
pub fn save_user_workspaces_op(
  uid: i64,
  mut conn: DBConnection,
  user_workspaces: &[UserWorkspace],
) -> Result<(), FlowyError> {
  conn.immediate_transaction(|conn| {
    delete_existing_workspaces(uid, conn)?;
    insert_new_workspaces_op(uid, user_workspaces, conn)?;
    Ok(())
  })
}

#[allow(dead_code)]
fn delete_existing_workspaces(uid: i64, conn: &mut SqliteConnection) -> Result<(), FlowyError> {
  diesel::delete(
    user_workspace_table::dsl::user_workspace_table.filter(user_workspace_table::uid.eq(uid)),
  )
  .execute(conn)?;
  Ok(())
}

pub fn insert_new_workspaces_op(
  uid: i64,
  user_workspaces: &[UserWorkspace],
  conn: &mut SqliteConnection,
) -> Result<(), FlowyError> {
  for user_workspace in user_workspaces {
    let new_record = UserWorkspaceTable::try_from((uid, user_workspace))?;
    diesel::insert_into(user_workspace_table::table)
      .values(new_record)
      .execute(conn)?;
  }
  Ok(())
}

impl TryFrom<(i64, &UserWorkspace)> for UserWorkspaceTable {
  type Error = FlowyError;

  fn try_from(value: (i64, &UserWorkspace)) -> Result<Self, Self::Error> {
    if value.1.id.is_empty() {
      return Err(FlowyError::invalid_data().with_context("The id is empty"));
    }
    if value.1.workspace_database_object_id.is_empty() {
      return Err(FlowyError::invalid_data().with_context("The database storage id is empty"));
    }

    Ok(Self {
      id: value.1.id.clone(),
      name: value.1.name.clone(),
      uid: value.0,
      created_at: value.1.created_at.timestamp(),
      database_storage_id: value.1.workspace_database_object_id.clone(),
      icon: value.1.icon.clone(),
    })
  }
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
      workspace_database_object_id: value.database_storage_id,
      icon: value.icon,
    }
  }
}

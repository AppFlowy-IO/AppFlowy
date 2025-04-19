use chrono::{TimeZone, Utc};
use diesel::RunQueryDsl;
use flowy_error::FlowyError;
use flowy_sqlite::schema::user_workspace_table;
use flowy_sqlite::DBConnection;
use flowy_sqlite::{query_dsl::*, ExpressionMethods};
use flowy_user_pub::entities::{AuthType, UserWorkspace};

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
) -> Option<UserWorkspaceTable> {
  user_workspace_table::dsl::user_workspace_table
    .filter(user_workspace_table::id.eq(workspace_id))
    .first::<UserWorkspaceTable>(&mut *conn)
    .ok()
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
  conn: &mut DBConnection,
) -> Result<(), FlowyError> {
  let new_record = UserWorkspaceTable::from_workspace(uid, &user_workspace, auth_type)?;

  diesel::insert_into(user_workspace_table::table)
    .values(new_record.clone())
    .on_conflict(user_workspace_table::id)
    .do_update()
    .set((
      user_workspace_table::name.eq(new_record.name),
      user_workspace_table::uid.eq(new_record.uid),
      user_workspace_table::created_at.eq(new_record.created_at),
      user_workspace_table::database_storage_id.eq(new_record.database_storage_id),
      user_workspace_table::icon.eq(new_record.icon),
      user_workspace_table::member_count.eq(new_record.member_count),
      user_workspace_table::role.eq(new_record.role),
      user_workspace_table::auth_type.eq(new_record.auth_type),
    ))
    .execute(conn)?;

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

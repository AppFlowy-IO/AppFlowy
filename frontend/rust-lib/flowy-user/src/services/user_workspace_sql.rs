use chrono::{TimeZone, Utc};

use flowy_sqlite::schema::user_workspace_table;
use flowy_user_deps::entities::UserWorkspace;

#[derive(Clone, Default, Queryable, Identifiable, Insertable)]
#[table_name = "user_workspace_table"]
pub struct UserWorkspaceTable {
  pub id: String,
  pub name: String,
  pub uid: i64,
  pub created_at: i64,
  pub database_storage_id: String,
}

impl From<(i64, &UserWorkspace)> for UserWorkspaceTable {
  fn from(value: (i64, &UserWorkspace)) -> Self {
    Self {
      id: value.1.id.clone(),
      name: value.1.name.clone(),
      uid: value.0,
      created_at: value.1.created_at.timestamp(),
      database_storage_id: value.1.database_storage_id.clone(),
    }
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
      database_storage_id: "".to_string(),
    }
  }
}

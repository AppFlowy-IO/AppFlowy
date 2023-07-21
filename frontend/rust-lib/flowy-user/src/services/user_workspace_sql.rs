use flowy_sqlite::{
  query_dsl::*,
  schema::{user_workspace_table, user_workspace_table::dsl},
  DBConnection, Database,
};

use crate::event_map::UserWorkspace;

#[derive(Clone, Default, Queryable, Identifiable, Insertable)]
#[table_name = "user_workspace_table"]
pub struct UserWorkspaceTable {
  pub id: String,
  pub name: String,
  pub created_at: i64,
  pub database_storage_id: String,
}

impl From<&UserWorkspace> for UserWorkspaceTable {
  fn from(value: &UserWorkspace) -> Self {
    Self {
      id: value.id.clone(),
      name: value.name.clone(),
      created_at: value.created_at.timestamp(),
      database_storage_id: value.database_storage_id.clone(),
    }
  }
}

use std::convert::TryFrom;

use chrono::{TimeZone, Utc};

use flowy_error::FlowyError;
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

impl TryFrom<(i64, &UserWorkspace)> for UserWorkspaceTable {
  type Error = FlowyError;

  fn try_from(value: (i64, &UserWorkspace)) -> Result<Self, Self::Error> {
    if value.1.id.is_empty() {
      return Err(FlowyError::invalid_data().with_context("The id is empty"));
    }
    if value.1.database_views_aggregate_id.is_empty() {
      return Err(FlowyError::invalid_data().with_context("The database storage id is empty"));
    }

    Ok(Self {
      id: value.1.id.clone(),
      name: value.1.name.clone(),
      uid: value.0,
      created_at: value.1.created_at.timestamp(),
      database_storage_id: value.1.database_views_aggregate_id.clone(),
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
      database_views_aggregate_id: value.database_storage_id,
    }
  }
}

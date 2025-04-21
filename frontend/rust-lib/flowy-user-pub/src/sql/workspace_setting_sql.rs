use client_api::entity::AFWorkspaceSettings;
use flowy_error::FlowyError;
use flowy_sqlite::schema::workspace_setting_table;
use flowy_sqlite::schema::workspace_setting_table::dsl;
use flowy_sqlite::DBConnection;
use flowy_sqlite::{prelude::*, ExpressionMethods};
use uuid::Uuid;

#[derive(Clone, Default, Queryable, Identifiable, Insertable)]
#[diesel(table_name = workspace_setting_table)]
pub struct WorkspaceSettingsTable {
  pub id: String,
  pub disable_search_indexing: bool,
  pub ai_model: String,
}

#[derive(AsChangeset, Identifiable, Default, Debug)]
#[diesel(table_name = workspace_setting_table)]
pub struct WorkspaceSettingsChangeset {
  pub id: String,
  pub disable_search_indexing: Option<bool>,
  pub ai_model: Option<String>,
}

impl WorkspaceSettingsTable {
  pub fn from_workspace_settings(workspace_id: &Uuid, settings: &AFWorkspaceSettings) -> Self {
    Self {
      id: workspace_id.to_string(),
      disable_search_indexing: settings.disable_search_indexing,
      ai_model: settings.ai_model.clone(),
    }
  }
}

pub fn update_workspace_setting(
  conn: &mut DBConnection,
  changeset: WorkspaceSettingsChangeset,
) -> Result<(), FlowyError> {
  diesel::update(dsl::workspace_setting_table)
    .filter(workspace_setting_table::id.eq(changeset.id.clone()))
    .set(changeset)
    .execute(conn)?;
  Ok(())
}

/// Upserts a workspace setting into the database.
pub fn upsert_workspace_setting(
  conn: &mut SqliteConnection,
  settings: WorkspaceSettingsTable,
) -> Result<(), FlowyError> {
  diesel::insert_into(dsl::workspace_setting_table)
    .values(settings.clone())
    .on_conflict(workspace_setting_table::id)
    .do_update()
    .set((
      workspace_setting_table::disable_search_indexing.eq(settings.disable_search_indexing),
      workspace_setting_table::ai_model.eq(settings.ai_model),
    ))
    .execute(conn)?;
  Ok(())
}

/// Selects a workspace setting by id from the database.
pub fn select_workspace_setting(
  conn: &mut SqliteConnection,
  workspace_id: &str,
) -> Result<WorkspaceSettingsTable, FlowyError> {
  let setting = dsl::workspace_setting_table
    .filter(workspace_setting_table::id.eq(workspace_id))
    .first::<WorkspaceSettingsTable>(conn)?;
  Ok(setting)
}

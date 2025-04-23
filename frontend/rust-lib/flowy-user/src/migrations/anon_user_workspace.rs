use diesel::SqliteConnection;
use semver::Version;
use std::sync::Arc;
use tracing::instrument;

use collab_integrate::CollabKVDB;
use flowy_error::FlowyResult;
use flowy_sqlite::kv::KVStorePreferences;
use flowy_user_pub::entities::AuthType;

use crate::migrations::migration::UserDataMigration;
use crate::migrations::session_migration::get_session_workspace;
use flowy_user_pub::session::Session;
use flowy_user_pub::sql::{select_user_workspace, upsert_user_workspace};

pub struct AnonUserWorkspaceTableMigration;

impl UserDataMigration for AnonUserWorkspaceTableMigration {
  fn name(&self) -> &str {
    "anon_user_workspace_table_migration"
  }

  fn run_when(
    &self,
    first_installed_version: &Option<Version>,
    _current_version: &Version,
  ) -> bool {
    match first_installed_version {
      None => true,
      Some(version) => version <= &Version::new(0, 8, 10),
    }
  }

  #[instrument(name = "AnonUserWorkspaceTableMigration", skip_all, err)]
  fn run(
    &self,
    user: &Session,
    _collab_db: &Arc<CollabKVDB>,
    user_auth_type: &AuthType,
    db: &mut SqliteConnection,
    store_preferences: &Arc<KVStorePreferences>,
  ) -> FlowyResult<()> {
    // For historical reason, anon user doesn't have a workspace in user_workspace_table.
    // So we need to create a new entry for the anon user in the user_workspace_table.
    if matches!(user_auth_type, AuthType::Local) {
      if let Some(mut user_workspace) = get_session_workspace(store_preferences) {
        if select_user_workspace(&user_workspace.id, db).ok().is_none() {
          user_workspace.workspace_type = AuthType::Local;
          upsert_user_workspace(user.user_id, *user_auth_type, user_workspace, db)?;
        }
      }
    }

    Ok(())
  }
}

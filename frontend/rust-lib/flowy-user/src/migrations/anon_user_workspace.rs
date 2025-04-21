use diesel::SqliteConnection;
use semver::Version;
use std::sync::Arc;
use tracing::{info, instrument};

use collab_integrate::CollabKVDB;
use flowy_error::FlowyResult;
use flowy_user_pub::entities::AuthType;

use crate::migrations::migration::UserDataMigration;
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
    session: &Session,
    _collab_db: &Arc<CollabKVDB>,
    auth_type: &AuthType,
    db: &mut SqliteConnection,
  ) -> FlowyResult<()> {
    // For historical reason, anon user doesn't have a workspace in user_workspace_table.
    // So we need to create a new entry for the anon user in the user_workspace_table.
    if matches!(auth_type, AuthType::Local) {
      let user_workspace = &session.user_workspace;
      let result = select_user_workspace(&user_workspace.id, db);
      if let Err(e) = result {
        if e.is_record_not_found() {
          info!(
            "Anon user workspace not found in the database, creating a new entry for user_id: {}",
            session.user_id
          );
          upsert_user_workspace(session.user_id, *auth_type, user_workspace.clone(), db)?;
        }
      }
    }

    Ok(())
  }
}

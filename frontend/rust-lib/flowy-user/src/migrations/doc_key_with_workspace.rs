use std::sync::{Arc, Weak};

use collab_plugins::local_storage::kv::doc::migrate_old_keys;
use collab_plugins::local_storage::kv::KVTransactionDB;
use diesel::SqliteConnection;
use semver::Version;
use tracing::{instrument, trace};

use collab_integrate::CollabKVDB;
use flowy_error::{FlowyError, FlowyResult};
use flowy_sqlite::kv::KVStorePreferences;
use flowy_user_pub::entities::AuthType;

use crate::migrations::migration::UserDataMigration;
use flowy_user_pub::session::Session;

pub struct CollabDocKeyWithWorkspaceIdMigration;

impl UserDataMigration for CollabDocKeyWithWorkspaceIdMigration {
  fn name(&self) -> &str {
    "collab_doc_key_with_workspace_id"
  }

  fn run_when(
    &self,
    first_installed_version: &Option<Version>,
    _current_version: &Version,
  ) -> bool {
    match first_installed_version {
      None => {
        // The user's initial installed version is None if they were using an AppFlowy version
        // lower than 0.7.3 and then upgraded to the latest version.
        true
      },
      Some(version) => version < &Version::new(0, 7, 3),
    }
  }

  #[instrument(name = "CollabDocKeyWithWorkspaceIdMigration", skip_all, err)]
  fn run(
    &self,
    user: &Session,
    collab_db: &Weak<CollabKVDB>,
    _user_auth_type: &AuthType,
    _db: &mut SqliteConnection,
    _store_preferences: &Arc<KVStorePreferences>,
  ) -> FlowyResult<()> {
    let collab_db = collab_db
      .upgrade()
      .ok_or_else(|| FlowyError::internal().with_context("Failed to upgrade DB object"))?;
    trace!("migrate key with workspace id:{}", user.workspace_id);
    collab_db.with_write_txn(|txn| {
      migrate_old_keys(txn, &user.workspace_id)?;
      Ok(())
    })?;
    Ok(())
  }
}

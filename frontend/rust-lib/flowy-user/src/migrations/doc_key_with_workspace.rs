use std::sync::Arc;

use collab_plugins::local_storage::kv::doc::migrate_old_keys;
use collab_plugins::local_storage::kv::KVTransactionDB;
use semver::Version;
use tracing::{instrument, trace};

use collab_integrate::CollabKVDB;
use flowy_error::FlowyResult;
use flowy_user_pub::entities::Authenticator;

use crate::migrations::migration::UserDataMigration;
use flowy_user_pub::session::Session;

pub struct CollabDocKeyWithWorkspaceIdMigration;

impl UserDataMigration for CollabDocKeyWithWorkspaceIdMigration {
  fn name(&self) -> &str {
    "collab_doc_key_with_workspace_id"
  }

  fn run_when(&self, first_installed_version: &Option<Version>, _current_version: &Version) -> bool {
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
    session: &Session,
    collab_db: &Arc<CollabKVDB>,
    _authenticator: &Authenticator,
  ) -> FlowyResult<()> {
    trace!(
      "migrate key with workspace id:{}",
      session.user_workspace.id
    );
    collab_db.with_write_txn(|txn| {
      migrate_old_keys(txn, &session.user_workspace.id)?;
      Ok(())
    })?;
    Ok(())
  }
}

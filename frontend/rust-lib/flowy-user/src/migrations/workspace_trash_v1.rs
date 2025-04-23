use std::sync::{Arc, Weak};

use collab_folder::Folder;
use collab_plugins::local_storage::kv::{KVTransactionDB, PersistenceError};
use diesel::SqliteConnection;
use semver::Version;
use tracing::instrument;

use collab_integrate::{CollabKVAction, CollabKVDB};
use flowy_error::{FlowyError, FlowyResult};
use flowy_sqlite::kv::KVStorePreferences;
use flowy_user_pub::entities::AuthType;

use crate::migrations::migration::UserDataMigration;
use crate::migrations::util::load_collab;
use flowy_user_pub::session::Session;

/// Migrate the workspace: { trash: [view_id] } to { trash: { uid: [view_id] } }
pub struct WorkspaceTrashMapToSectionMigration;

impl UserDataMigration for WorkspaceTrashMapToSectionMigration {
  fn name(&self) -> &str {
    "workspace_trash_map_to_section_migration"
  }

  fn run_when(
    &self,
    first_installed_version: &Option<Version>,
    _current_version: &Version,
  ) -> bool {
    match first_installed_version {
      None => true,
      Some(version) => version < &Version::new(0, 4, 0),
    }
  }

  #[instrument(name = "WorkspaceTrashMapToSectionMigration", skip_all, err)]
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
    collab_db.with_write_txn(|write_txn| {
      if let Ok(collab) = load_collab(
        user.user_id,
        write_txn,
        &user.workspace_id,
        &user.workspace_id,
      ) {
        let mut folder = Folder::open(user.user_id, collab, None)
          .map_err(|err| PersistenceError::Internal(err.into()))?;
        let trash_ids = folder
          .get_trash_v1()
          .into_iter()
          .map(|fav| fav.id)
          .collect::<Vec<String>>();

        if !trash_ids.is_empty() {
          folder.add_trash_view_ids(trash_ids);
        }

        let encode = folder
          .encode_collab()
          .map_err(|err| PersistenceError::Internal(err.into()))?;
        write_txn.flush_doc(
          user.user_id,
          &user.workspace_id,
          &user.workspace_id,
          encode.state_vector.to_vec(),
          encode.doc_state.to_vec(),
        )?;
      }
      Ok(())
    })?;

    Ok(())
  }
}

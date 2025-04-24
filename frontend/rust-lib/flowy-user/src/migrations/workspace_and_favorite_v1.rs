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

/// 1. Migrate the workspace: { favorite: [view_id] } to { favorite: { uid: [view_id] } }
/// 2. Migrate { workspaces: [workspace object] } to { views: { workspace object } }. Make each folder
///    only have one workspace.
pub struct FavoriteV1AndWorkspaceArrayMigration;

impl UserDataMigration for FavoriteV1AndWorkspaceArrayMigration {
  fn name(&self) -> &str {
    "workspace_favorite_v1_and_workspace_array_migration"
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

  #[instrument(name = "FavoriteV1AndWorkspaceArrayMigration", skip_all, err)]
  fn run(
    &self,
    uid: i64,
    workspace_id: &str,
    collab_db: &Weak<CollabKVDB>,
    _user_auth_type: &AuthType,
    _db: &mut SqliteConnection,
    _store_preferences: &Arc<KVStorePreferences>,
  ) -> FlowyResult<()> {
    let collab_db = collab_db
      .upgrade()
      .ok_or_else(|| FlowyError::internal().with_context("Failed to upgrade DB object"))?;
    collab_db.with_write_txn(|write_txn| {
      if let Ok(collab) = load_collab(uid, write_txn, workspace_id, workspace_id) {
        let mut folder =
          Folder::open(uid, collab, None).map_err(|err| PersistenceError::Internal(err.into()))?;
        folder
          .body
          .migrate_workspace_to_view(&mut folder.collab.transact_mut());

        let favorite_view_ids = folder
          .get_favorite_v1()
          .into_iter()
          .map(|fav| fav.id)
          .collect::<Vec<String>>();

        if !favorite_view_ids.is_empty() {
          folder.add_favorite_view_ids(favorite_view_ids);
        }

        let encode = folder
          .encode_collab()
          .map_err(|err| PersistenceError::Internal(err.into()))?;
        write_txn.flush_doc(
          uid,
          workspace_id,
          workspace_id,
          encode.state_vector.to_vec(),
          encode.doc_state.to_vec(),
        )?;
      }
      Ok(())
    })?;

    Ok(())
  }
}

use std::sync::Arc;

use collab_folder::Folder;
use collab_plugins::local_storage::kv::{KVTransactionDB, PersistenceError};
use tracing::instrument;

use collab_integrate::{CollabKVAction, CollabKVDB};
use flowy_error::FlowyResult;
use flowy_user_pub::entities::Authenticator;

use crate::migrations::migration::UserDataMigration;
use crate::migrations::util::load_collab;
use flowy_user_pub::session::Session;

/// 1. Migrate the workspace: { favorite: [view_id] } to { favorite: { uid: [view_id] } }
/// 2. Migrate { workspaces: [workspace object] } to { views: { workspace object } }. Make each folder
/// only have one workspace.
pub struct FavoriteV1AndWorkspaceArrayMigration;

impl UserDataMigration for FavoriteV1AndWorkspaceArrayMigration {
  fn name(&self) -> &str {
    "workspace_favorite_v1_and_workspace_array_migration"
  }

  #[instrument(name = "FavoriteV1AndWorkspaceArrayMigration", skip_all, err)]
  fn run(
    &self,
    session: &Session,
    collab_db: &Arc<CollabKVDB>,
    _authenticator: &Authenticator,
  ) -> FlowyResult<()> {
    collab_db.with_write_txn(|write_txn| {
      if let Ok(collab) = load_collab(session.user_id, write_txn, &session.user_workspace.id) {
        let folder = Folder::open(session.user_id, collab, None)
          .map_err(|err| PersistenceError::Internal(err.into()))?;
        folder.migrate_workspace_to_view();

        let favorite_view_ids = folder
          .get_favorite_v1()
          .into_iter()
          .map(|fav| fav.id)
          .collect::<Vec<String>>();

        if !favorite_view_ids.is_empty() {
          folder.add_favorite_view_ids(favorite_view_ids);
        }

        let encode = folder.encode_collab_v1();
        write_txn.flush_doc_with(
          session.user_id,
          &session.user_workspace.id,
          &encode.doc_state,
          &encode.state_vector,
        )?;
      }
      Ok(())
    })?;

    Ok(())
  }
}

use std::sync::Arc;

use collab_folder::Folder;
use tracing::instrument;

use collab_integrate::{RocksCollabDB, YrsDocAction};
use flowy_error::{internal_error, FlowyResult};

use crate::migrations::migration::UserDataMigration;
use crate::migrations::util::load_collab;
use crate::services::entities::Session;

/// 1. Migrate the workspace: { favorite: [view_id] } to { favorite: { uid: [view_id] } }
/// 2. Migrate { workspaces: [workspace object] } to { views: { workspace object } }. Make each folder
/// only have one workspace.
pub struct FavoriteV1AndWorkspaceArrayMigration;

impl UserDataMigration for FavoriteV1AndWorkspaceArrayMigration {
  fn name(&self) -> &str {
    "workspace_favorite_v1_and_workspace_array_migration"
  }

  #[instrument(name = "FavoriteV1AndWorkspaceArrayMigration", skip_all, err)]
  fn run(&self, session: &Session, collab_db: &Arc<RocksCollabDB>) -> FlowyResult<()> {
    let write_txn = collab_db.write_txn();
    if let Ok(collab) = load_collab(session.user_id, &write_txn, &session.user_workspace.id) {
      let folder = Folder::open(session.user_id, collab, None)?;
      folder.migrate_workspace_to_view();

      let favorite_view_ids = folder
        .get_favorite_v1()
        .into_iter()
        .map(|fav| fav.id)
        .collect::<Vec<String>>();

      if !favorite_view_ids.is_empty() {
        folder.add_favorites(favorite_view_ids);
      }

      let encode = folder.encode_collab_v1();
      write_txn
        .flush_doc_with(
          session.user_id,
          &session.user_workspace.id,
          &encode.doc_state,
          &encode.state_vector,
        )
        .map_err(internal_error)?;
    }

    write_txn.commit_transaction().map_err(internal_error)?;
    Ok(())
  }
}

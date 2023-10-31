use std::sync::Arc;

use collab::core::origin::{CollabClient, CollabOrigin};
use collab_folder::Folder;

use collab_integrate::{RocksCollabDB, YrsDocAction};
use flowy_error::{internal_error, FlowyResult};

use crate::migrations::migration::UserDataMigration;
use crate::services::entities::Session;

/// 1. Migrate the workspace: { favorite: [view_id] } to { favorite: { uid: [view_id] } }
/// 2. Migrate { workspaces: [workspace object] } to { views: { workspace object } }. Make each folder
/// only have one workspace.
pub struct FavoriteV1AndWorkspaceArrayMigration;

impl UserDataMigration for FavoriteV1AndWorkspaceArrayMigration {
  fn name(&self) -> &str {
    "workspace_favorite_v1_and_workspace_array_migration"
  }

  fn run(&self, session: &Session, collab_db: &Arc<RocksCollabDB>) -> FlowyResult<()> {
    let write_txn = collab_db.write_txn();
    if let Ok(updates) = write_txn.get_all_updates(session.user_id, &session.user_workspace.id) {
      let origin = CollabOrigin::Client(CollabClient::new(session.user_id, "phantom"));
      // Deserialize the folder from the raw data
      let folder = Folder::from_collab_raw_data(
        session.user_id,
        origin,
        updates,
        &session.user_workspace.id,
        vec![],
      )?;

      folder.migrate_workspace_to_view();

      let favorite_view_ids = folder
        .get_favorite_v1()
        .into_iter()
        .map(|fav| fav.id)
        .collect::<Vec<String>>();

      if !favorite_view_ids.is_empty() {
        folder.add_favorites(favorite_view_ids);
      }

      let (doc_state, sv) = folder.encode_as_update_v1();
      write_txn
        .flush_doc_with(session.user_id, &session.user_workspace.id, &doc_state, &sv)
        .map_err(internal_error)?;
      write_txn.commit_transaction().map_err(internal_error)?;
    }
    Ok(())
  }
}

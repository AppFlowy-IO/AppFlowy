use std::sync::Arc;

use collab_folder::Folder;
use tracing::instrument;

use collab_integrate::{RocksCollabDB, YrsDocAction};
use flowy_error::{internal_error, FlowyResult};
use flowy_user_deps::entities::Authenticator;

use crate::migrations::migration::UserDataMigration;
use crate::migrations::util::load_collab;
use crate::services::entities::Session;

/// 1. Migrate the workspace: { trash: [view_id] } to { trash: { uid: [view_id] } }
pub struct WorkspaceTrashMapToSectionMigration;

impl UserDataMigration for WorkspaceTrashMapToSectionMigration {
  fn name(&self) -> &str {
    "workspace_trash_map_to_section_migration"
  }

  #[instrument(name = "WorkspaceTrashMapToSectionMigration", skip_all, err)]
  fn run(
    &self,
    session: &Session,
    collab_db: &Arc<RocksCollabDB>,
    authenticator: &Authenticator,
  ) -> FlowyResult<()> {
    // Note on `favorite` Struct Refactoring and Migration:
    // - The `favorite` struct has already undergone refactoring prior to the launch of the AppFlowy cloud version.
    // - Consequently, if a user is utilizing the AppFlowy cloud version, there is no need to perform any migration for the `favorite` struct.
    // - This migration step is only necessary for users who are transitioning from a local version of AppFlowy to the cloud version.
    if !matches!(authenticator, Authenticator::Local) {
      return Ok(());
    }

    let write_txn = collab_db.write_txn();
    if let Ok(collab) = load_collab(session.user_id, &write_txn, &session.user_workspace.id) {
      let folder = Folder::open(session.user_id, collab, None)?;
      let trash_ids = folder
        .get_trash_v1()
        .into_iter()
        .map(|fav| fav.id)
        .collect::<Vec<String>>();

      if !trash_ids.is_empty() {
        folder.add_trash(trash_ids);
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

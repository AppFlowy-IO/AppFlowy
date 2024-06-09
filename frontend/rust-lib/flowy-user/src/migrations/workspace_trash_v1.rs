use std::sync::Arc;

use collab_folder::Folder;
use collab_plugins::local_storage::kv::{KVTransactionDB, PersistenceError};
use semver::Version;
use tracing::instrument;

use collab_integrate::{CollabKVAction, CollabKVDB};
use flowy_error::FlowyResult;
use flowy_user_pub::entities::Authenticator;

use crate::migrations::migration::UserDataMigration;
use crate::migrations::util::load_collab;
use flowy_user_pub::session::Session;

/// Migrate the workspace: { trash: [view_id] } to { trash: { uid: [view_id] } }
pub struct WorkspaceTrashMapToSectionMigration;

impl UserDataMigration for WorkspaceTrashMapToSectionMigration {
  fn name(&self) -> &str {
    "workspace_trash_map_to_section_migration"
  }

  fn applies_to_version(&self, _app_version: &Version) -> bool {
    true
  }

  #[instrument(name = "WorkspaceTrashMapToSectionMigration", skip_all, err)]
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
        let trash_ids = folder
          .get_trash_v1()
          .into_iter()
          .map(|fav| fav.id)
          .collect::<Vec<String>>();

        if !trash_ids.is_empty() {
          folder.add_trash_view_ids(trash_ids);
        }

        let encode = folder
          .encode_collab_v1()
          .map_err(|err| PersistenceError::Internal(err.into()))?;
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

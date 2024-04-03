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

/// Migrate the workspace: Add all the view_ids in the view_map into the private section
pub struct WorkspacePrivateSectionMigration;

impl UserDataMigration for WorkspacePrivateSectionMigration {
  fn name(&self) -> &str {
    "workspace_private_section_migration"
  }

  #[instrument(name = "WorkspacePrivateSectionMigration", skip_all, err)]
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

        let view_ids = folder
          .get_workspace_views()
          .into_iter()
          .map(|view| view.id.clone())
          .collect::<Vec<String>>();

        if !view_ids.is_empty() {
          folder.add_private_view_ids(view_ids);
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

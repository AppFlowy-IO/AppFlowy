use std::sync::Arc;

use appflowy_integrate::{RocksCollabDB, YrsDocAction};
use collab::core::collab::MutexCollab;
use collab::core::origin::{CollabClient, CollabOrigin};
use collab_document::document::Document;
use collab_document::document_data::default_document_data;
use collab_folder::core::Folder;

use flowy_error::{internal_error, FlowyResult};

use crate::migrations::migration::UserDataMigration;
use crate::services::entities::Session;

/// Migrate the first level documents of the workspace by inserting documents
pub struct HistoricalEmptyDocumentMigration;

impl UserDataMigration for HistoricalEmptyDocumentMigration {
  fn name(&self) -> &str {
    "historical_empty_document"
  }

  fn run(&self, session: &Session, collab_db: &Arc<RocksCollabDB>) -> FlowyResult<()> {
    let write_txn = collab_db.write_txn();
    if let Ok(updates) = write_txn.get_all_updates(session.user_id, &session.user_workspace.id) {
      let origin = CollabOrigin::Client(CollabClient::new(session.user_id, "phantom"));
      // Deserialize the folder from the raw data
      let folder =
        Folder::from_collab_raw_data(origin.clone(), updates, &session.user_workspace.id, vec![])?;

      // Migration the first level documents of the workspace
      let migration_views = folder.get_workspace_views(&session.user_workspace.id);
      for view in migration_views {
        // Read all updates of the view
        if let Ok(view_updates) = write_txn.get_all_updates(session.user_id, &view.id) {
          if Document::from_updates(origin.clone(), view_updates, &view.id, vec![]).is_err() {
            // Create a document with default data
            let document_data = default_document_data();
            let collab = Arc::new(MutexCollab::new(origin.clone(), &view.id, vec![]));
            if let Ok(document) = Document::create_with_data(collab.clone(), document_data) {
              // Remove all old updates and then insert the new update
              let (doc_state, sv) = document.get_collab().encode_as_update_v1();
              write_txn
                .flush_doc_with(session.user_id, &view.id, &doc_state, &sv)
                .map_err(internal_error)?;
            }
          }
        }
      }
    }
    write_txn.commit_transaction().map_err(internal_error)?;
    Ok(())
  }
}

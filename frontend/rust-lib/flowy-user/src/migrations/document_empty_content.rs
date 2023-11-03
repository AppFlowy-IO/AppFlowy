use std::sync::Arc;

use collab::core::collab::MutexCollab;
use collab::core::origin::{CollabClient, CollabOrigin};
use collab_document::document::Document;
use collab_document::document_data::default_document_data;
use collab_folder::Folder;
use tracing::instrument;

use collab_integrate::{RocksCollabDB, YrsDocAction};
use flowy_error::{internal_error, FlowyResult};

use crate::migrations::migration::UserDataMigration;
use crate::migrations::util::load_collab;
use crate::services::entities::Session;

/// Migrate the first level documents of the workspace by inserting documents
pub struct HistoricalEmptyDocumentMigration;

impl UserDataMigration for HistoricalEmptyDocumentMigration {
  fn name(&self) -> &str {
    "historical_empty_document"
  }

  #[instrument(name = "HistoricalEmptyDocumentMigration", skip_all, err)]
  fn run(&self, session: &Session, collab_db: &Arc<RocksCollabDB>) -> FlowyResult<()> {
    let write_txn = collab_db.write_txn();
    let origin = CollabOrigin::Client(CollabClient::new(session.user_id, "phantom"));
    // Deserialize the folder from the raw data
    if let Ok(folder_collab) = load_collab(session.user_id, &write_txn, &session.user_workspace.id)
    {
      let folder = Folder::open(session.user_id, folder_collab, None)?;

      // Migration the first level documents of the workspace
      let migration_views = folder.get_workspace_views(&session.user_workspace.id);
      for view in migration_views {
        // Read all updates of the view

        if let Ok(document_collab) = load_collab(session.user_id, &write_txn, &view.id) {
          if Document::open(document_collab).is_err() {
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

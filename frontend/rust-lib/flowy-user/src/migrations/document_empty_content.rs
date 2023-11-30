use std::sync::Arc;

use collab::core::collab::MutexCollab;
use collab::core::origin::{CollabClient, CollabOrigin};
use collab_document::document::Document;
use collab_document::document_data::default_document_data;
use collab_folder::Folder;
use tracing::{event, instrument};

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

      // Migration the first level documents of the workspace. The first level documents do not have
      // any updates. So when calling load_collab, it will return error.
      let migration_views = folder.get_workspace_views();
      for view in migration_views {
        if load_collab(session.user_id, &write_txn, &view.id).is_err() {
          // Create a document with default data
          let document_data = default_document_data();
          let collab = Arc::new(MutexCollab::new(origin.clone(), &view.id, vec![]));
          if let Ok(document) = Document::create_with_data(collab.clone(), document_data) {
            // Remove all old updates and then insert the new update
            let encode = document.get_collab().encode_collab_v1();
            if let Err(err) = write_txn.flush_doc_with(
              session.user_id,
              &view.id,
              &encode.doc_state,
              &encode.state_vector,
            ) {
              event!(
                tracing::Level::ERROR,
                "Failed to migrate document {}, error: {}",
                view.id,
                err
              );
            } else {
              event!(tracing::Level::INFO, "Did migrate document {}", view.id);
            }
          }
        }
      }
    }

    event!(tracing::Level::INFO, "Save all migrated documents");
    write_txn.commit_transaction().map_err(internal_error)?;
    Ok(())
  }
}

use std::sync::Arc;

use collab::core::origin::{CollabClient, CollabOrigin};
use collab::preclude::Collab;
use collab_document::document::Document;
use collab_document::document_data::default_document_data;
use collab_folder::{Folder, View};
use collab_plugins::local_storage::kv::KVTransactionDB;
use semver::Version;
use tracing::{event, instrument};

use collab_integrate::{CollabKVAction, CollabKVDB, PersistenceError};
use flowy_error::{FlowyError, FlowyResult};
use flowy_user_pub::entities::Authenticator;

use crate::migrations::migration::UserDataMigration;
use crate::migrations::util::load_collab;
use flowy_user_pub::session::Session;

/// Migrate the first level documents of the workspace by inserting documents
pub struct HistoricalEmptyDocumentMigration;

impl UserDataMigration for HistoricalEmptyDocumentMigration {
  fn name(&self) -> &str {
    "historical_empty_document"
  }

  fn applies_to_version(&self, _version: &Version) -> bool {
    true
  }

  #[instrument(name = "HistoricalEmptyDocumentMigration", skip_all, err)]
  fn run(
    &self,
    session: &Session,
    collab_db: &Arc<CollabKVDB>,
    authenticator: &Authenticator,
  ) -> FlowyResult<()> {
    // - The `empty document` struct has already undergone refactoring prior to the launch of the AppFlowy cloud version.
    // - Consequently, if a user is utilizing the AppFlowy cloud version, there is no need to perform any migration for the `empty document` struct.
    // - This migration step is only necessary for users who are transitioning from a local version of AppFlowy to the cloud version.
    if !matches!(authenticator, Authenticator::Local) {
      return Ok(());
    }
    collab_db.with_write_txn(|write_txn| {
      let origin = CollabOrigin::Client(CollabClient::new(session.user_id, "phantom"));
      let folder_collab = match load_collab(
        session.user_id,
        write_txn,
        &session.user_workspace.id,
        &session.user_workspace.id,
      ) {
        Ok(fc) => fc,
        Err(_) => return Ok(()),
      };

      let folder = Folder::open(session.user_id, folder_collab, None)
        .map_err(|err| PersistenceError::Internal(err.into()))?;
      if let Some(workspace_id) = folder.get_workspace_id() {
        let migration_views = folder.get_views_belong_to(&workspace_id);
        // For historical reasons, the first level documents are empty. So migrate them by inserting
        // the default document data.
        for view in migration_views {
          if migrate_empty_document(
            write_txn,
            &origin,
            &view,
            session.user_id,
            &session.user_workspace.id,
          )
          .is_err()
          {
            event!(
              tracing::Level::ERROR,
              "Failed to migrate document {}",
              view.id
            );
          }
        }
      }

      Ok(())
    })?;

    Ok(())
  }
}

fn migrate_empty_document<'a, W>(
  write_txn: &W,
  origin: &CollabOrigin,
  view: &View,
  user_id: i64,
  workspace_id: &str,
) -> Result<(), FlowyError>
where
  W: CollabKVAction<'a>,
  PersistenceError: From<W::Error>,
{
  // If the document is not exist, we don't need to migrate it.
  if load_collab(user_id, write_txn, workspace_id, &view.id).is_err() {
    let collab = Collab::new_with_origin(origin.clone(), &view.id, vec![], false);
    let document = Document::create_with_data(collab, default_document_data(&view.id))?;
    let encode = document.encode_collab_v1(|_| Ok::<(), PersistenceError>(()))?;
    write_txn.flush_doc(
      user_id,
      workspace_id,
      &view.id,
      encode.state_vector.to_vec(),
      encode.doc_state.to_vec(),
    )?;
    event!(
      tracing::Level::INFO,
      "Did migrate empty document {}",
      view.id
    );
  }

  Ok(())
}

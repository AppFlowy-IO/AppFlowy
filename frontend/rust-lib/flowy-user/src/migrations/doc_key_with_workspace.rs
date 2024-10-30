use std::sync::Arc;

use collab::core::origin::{CollabClient, CollabOrigin};
use collab::preclude::Collab;
use collab_document::document::Document;
use collab_document::document_data::default_document_data;
use collab_folder::{Folder, View};
use collab_plugins::local_storage::kv::doc::migrate_old_keys;
use collab_plugins::local_storage::kv::KVTransactionDB;
use semver::Version;
use tracing::{event, instrument};

use collab_integrate::{CollabKVAction, CollabKVDB, PersistenceError};
use flowy_error::{FlowyError, FlowyResult};
use flowy_user_pub::entities::Authenticator;

use crate::migrations::migration::UserDataMigration;
use crate::migrations::util::load_collab;
use flowy_user_pub::session::Session;

pub struct CollabDocKeyWithWorkspaceIdMigration;

impl UserDataMigration for CollabDocKeyWithWorkspaceIdMigration {
  fn name(&self) -> &str {
    "collab_doc_key_with_workspace_id"
  }

  fn applies_to_version(&self, _version: &Version) -> bool {
    true
  }

  #[instrument(name = "CollabDocKeyWithWorkspaceIdMigration", skip_all, err)]
  fn run(
    &self,
    session: &Session,
    collab_db: &Arc<CollabKVDB>,
    authenticator: &Authenticator,
  ) -> FlowyResult<()> {
    collab_db.with_write_txn(|txn| {
      migrate_old_keys(txn, &session.user_workspace.id)?;
      Ok(())
    })?;
    Ok(())
  }
}

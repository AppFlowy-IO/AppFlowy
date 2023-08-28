use std::sync::Weak;

use flowy_database2::DatabaseManager;
use flowy_document2::manager::DocumentManager;
use flowy_folder_deps::cloud::Error;
use flowy_user::services::collab_interact::{CollabInteract, Reminder};
use lib_infra::future::FutureResult;

pub struct CollabInteractImpl {
  pub(crate) database_manager: Weak<DatabaseManager>,
  pub(crate) document_manager: Weak<DocumentManager>,
}

impl CollabInteract for CollabInteractImpl {
  fn add_reminder(&self, reminder: &Reminder) -> FutureResult<(), Error> {
    todo!()
  }

  fn remove_reminder(&self, reminder_id: &str) -> FutureResult<(), Error> {
    todo!()
  }

  fn update_reminder(&self, reminder: &Reminder) -> FutureResult<(), Error> {
    todo!()
  }
}

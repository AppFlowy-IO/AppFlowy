use collab_entity::reminder::Reminder;
use std::convert::TryFrom;
use std::sync::Weak;

use flowy_database2::DatabaseManager;
use flowy_document::manager::DocumentManager;
use flowy_document::reminder::{DocumentReminder, DocumentReminderAction};
use flowy_folder_pub::cloud::Error;
use flowy_user::services::collab_interact::CollabInteract;
use lib_infra::future::FutureResult;

pub struct CollabInteractImpl {
  #[allow(dead_code)]
  pub(crate) database_manager: Weak<DatabaseManager>,
  #[allow(dead_code)]
  pub(crate) document_manager: Weak<DocumentManager>,
}

impl CollabInteract for CollabInteractImpl {
  fn add_reminder(&self, reminder: Reminder) -> FutureResult<(), Error> {
    let cloned_document_manager = self.document_manager.clone();
    FutureResult::new(async move {
      if let Some(document_manager) = cloned_document_manager.upgrade() {
        match DocumentReminder::try_from(reminder) {
          Ok(reminder) => {
            document_manager
              .handle_reminder_action(DocumentReminderAction::Add { reminder })
              .await;
          },
          Err(e) => tracing::error!("Failed to add reminder: {:?}", e),
        }
      }
      Ok(())
    })
  }

  fn remove_reminder(&self, reminder_id: &str) -> FutureResult<(), Error> {
    let reminder_id = reminder_id.to_string();
    let cloned_document_manager = self.document_manager.clone();
    FutureResult::new(async move {
      if let Some(document_manager) = cloned_document_manager.upgrade() {
        let action = DocumentReminderAction::Remove { reminder_id };
        document_manager.handle_reminder_action(action).await;
      }
      Ok(())
    })
  }

  fn update_reminder(&self, reminder: Reminder) -> FutureResult<(), Error> {
    let cloned_document_manager = self.document_manager.clone();
    FutureResult::new(async move {
      if let Some(document_manager) = cloned_document_manager.upgrade() {
        match DocumentReminder::try_from(reminder) {
          Ok(reminder) => {
            document_manager
              .handle_reminder_action(DocumentReminderAction::Update { reminder })
              .await;
          },
          Err(e) => tracing::error!("Failed to update reminder: {:?}", e),
        }
      }
      Ok(())
    })
  }
}

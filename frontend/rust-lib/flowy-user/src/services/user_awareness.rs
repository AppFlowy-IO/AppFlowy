use std::sync::{Arc, Weak};

use appflowy_integrate::{CollabType, RocksCollabDB};
use collab::core::collab::{CollabRawData, MutexCollab};
use collab_user::core::{MutexUserAwareness, Reminder, UserAwareness};

use flowy_error::{ErrorCode, FlowyError, FlowyResult};

use crate::entities::ReminderPB;
use crate::manager::UserManager;
use crate::services::entities::Session;

impl UserManager {
  pub async fn add_reminder(&self, payload: ReminderPB) -> FlowyResult<()> {
    let reminder = Reminder::from(payload);
    self.with_awareness((), |user_awareness| {
      user_awareness.add_reminder(reminder);
    });
    Ok(())
  }

  pub async fn get_all_reminders(&self) -> Vec<Reminder> {
    self.with_awareness(vec![], |user_awareness| user_awareness.get_all_reminders())
  }

  pub async fn initialize_user_awareness(
    &self,
    session: &Session,
    source: UserAwarenessDataSource,
  ) {
    match self.try_initial_user_awareness(session, source).await {
      Ok(_) => {},
      Err(e) => {
        tracing::error!("Failed to initialize user awareness: {:?}", e);
      },
    }
  }

  async fn try_initial_user_awareness(
    &self,
    session: &Session,
    source: UserAwarenessDataSource,
  ) -> FlowyResult<()> {
    tracing::trace!("Initializing user awareness from {:?}", source);
    let collab_db = self.get_collab_db(session.user_id)?;
    let user_awareness = match source {
      UserAwarenessDataSource::Local => {
        let collab = self.collab_for_user_awareness(session, collab_db, vec![])?;
        MutexUserAwareness::new(UserAwareness::create(collab, None))
      },
      UserAwarenessDataSource::Remote => {
        let data = self
          .cloud_services
          .get_user_service()?
          .get_user_awareness_updates(session.user_id)
          .await?;
        let collab = self.collab_for_user_awareness(session, collab_db, data)?;
        MutexUserAwareness::new(UserAwareness::create(collab, None))
      },
    };
    self.user_awareness.lock().replace(user_awareness);
    Ok(())
  }

  fn collab_for_user_awareness(
    &self,
    session: &Session,
    collab_db: Weak<RocksCollabDB>,
    raw_data: CollabRawData,
  ) -> Result<Arc<MutexCollab>, FlowyError> {
    let collab_builder = self.collab_builder.upgrade().ok_or(FlowyError::new(
      ErrorCode::Internal,
      "Unexpected error: collab builder is not available",
    ))?;
    let collab = collab_builder.build(
      session.user_id,
      &session.user_id.to_string(),
      CollabType::UserAwareness,
      raw_data,
      collab_db,
    )?;
    Ok(collab)
  }

  fn with_awareness<F, Output>(&self, default_value: Output, f: F) -> Output
  where
    F: FnOnce(&UserAwareness) -> Output,
  {
    let user_awareness = self.user_awareness.lock();
    match &*user_awareness {
      None => default_value,
      Some(user_awareness) => f(&*user_awareness.lock()),
    }
  }
}

#[derive(Debug)]
pub enum UserAwarenessDataSource {
  Local,
  Remote,
}

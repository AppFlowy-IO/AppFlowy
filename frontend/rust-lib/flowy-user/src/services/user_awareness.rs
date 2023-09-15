use std::sync::{Arc, Weak};

use appflowy_integrate::RocksCollabDB;
use collab::core::collab::{CollabRawData, MutexCollab};
use collab_define::reminder::Reminder;
use collab_define::CollabType;
use collab_user::core::{MutexUserAwareness, UserAwareness};

use flowy_error::{ErrorCode, FlowyError, FlowyResult};

use crate::entities::ReminderPB;
use crate::manager::UserManager;
use crate::services::entities::Session;

impl UserManager {
  /// Adds a new reminder based on the given payload.
  ///
  /// This function creates a new `Reminder` from the provided payload and adds it to the user's reminders.
  /// It leverages the `with_awareness` function to ensure the reminder is added in the context of the
  /// current user's awareness.
  ///
  /// # Parameters
  /// - `reminder_pb`: The pb for the new reminder.
  ///
  /// # Returns
  /// - Returns `Ok(())` if the reminder is successfully added.
  /// - May return errors of type `FlowyError` if any issues arise during the process.
  ///
  pub async fn add_reminder(&self, reminder_pb: ReminderPB) -> FlowyResult<()> {
    let reminder = Reminder::from(reminder_pb);
    self
      .with_awareness((), |user_awareness| {
        user_awareness.add_reminder(reminder);
      })
      .await;
    Ok(())
  }

  /// Retrieves all reminders for the user.
  ///
  /// This function fetches all reminders associated with the current user. It leverages the
  /// `with_awareness` function to ensure the reminders are retrieved in the context of the
  /// current user's awareness.
  ///
  /// # Returns
  /// - Returns a vector of `Reminder` objects containing all reminders for the user.
  ///
  pub async fn get_all_reminders(&self) -> Vec<Reminder> {
    self
      .with_awareness(vec![], |user_awareness| user_awareness.get_all_reminders())
      .await
  }

  pub async fn initialize_user_awareness(
    &self,
    session: &Session,
    source: UserAwarenessDataSource,
  ) {
    match self.try_initial_user_awareness(session, source).await {
      Ok(_) => {
        tracing::trace!("User awareness initialized");
      },
      Err(e) => {
        tracing::error!("Failed to initialize user awareness: {:?}", e);
      },
    }
  }

  /// Initializes the user's awareness based on the specified data source.
  ///
  /// This asynchronous function attempts to initialize the user's awareness from either a local or remote data source.
  /// Depending on the chosen source, it will either construct the user awareness from an empty dataset or fetch it
  /// from a remote service. Once obtained, the user's awareness is stored in a shared mutex-protected structure.
  ///
  /// # Parameters
  /// - `session`: The current user's session data.
  /// - `source`: The source from which the user's awareness data should be obtained, either local or remote.
  ///
  /// # Returns
  /// - Returns `Ok(())` if the user's awareness is successfully initialized.
  /// - May return errors of type `FlowyError` if any issues arise during the initialization.
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
    self.user_awareness.lock().await.replace(user_awareness);
    Ok(())
  }

  /// Creates a collaboration instance tailored for user awareness.
  ///
  /// This function constructs a collaboration instance based on the given session and raw data,
  /// using a collaboration builder. This instance is specifically geared towards handling
  /// user awareness.
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

  /// Executes a function with user awareness.
  ///
  /// This function takes an asynchronous closure `f` that accepts a reference to a `UserAwareness`
  /// and returns an `Output`. If the current user awareness is set (i.e., is `Some`), it invokes
  /// the closure `f` with the user awareness. If the user awareness is not set (i.e., is `None`),
  /// it attempts to initialize the user awareness via a remote session. If the session fetch
  /// or user awareness initialization fails, it returns the provided `default_value`.
  ///
  /// # Parameters
  /// - `default_value`: A default value to return if the user awareness is `None` and cannot be initialized.
  /// - `f`: The asynchronous closure to execute with the user awareness.
  async fn with_awareness<F, Output>(&self, default_value: Output, f: F) -> Output
  where
    F: FnOnce(&UserAwareness) -> Output,
  {
    let user_awareness = self.user_awareness.lock().await;
    match &*user_awareness {
      None => {
        if let Ok(session) = self.get_session() {
          self
            .initialize_user_awareness(&session, UserAwarenessDataSource::Remote)
            .await;
        }
        default_value
      },
      Some(user_awareness) => f(&user_awareness.lock()),
    }
  }
}

/// Indicate using which data source to initialize the user awareness
/// If the user is not a new user, the local data source is used. Otherwise, the remote data source is used.
/// When using the remote data source, the user awareness will be initialized from the remote server.
#[derive(Debug)]
pub enum UserAwarenessDataSource {
  Local,
  Remote,
}

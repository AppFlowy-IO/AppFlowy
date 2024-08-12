use std::sync::atomic::Ordering;
use std::sync::{Arc, Weak};

use anyhow::Context;
use collab::core::collab::DataSource;
use collab_entity::reminder::Reminder;
use collab_entity::CollabType;
use collab_integrate::collab_builder::{AppFlowyCollabBuilder, CollabBuilderConfig};
use collab_user::core::{UserAwareness, UserAwarenessNotifier};
use tokio::sync::RwLock;
use tracing::{debug, error, info, instrument, trace};

use collab_integrate::CollabKVDB;
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_user_pub::entities::user_awareness_object_id;

use crate::entities::ReminderPB;
use crate::user_manager::UserManager;
use flowy_user_pub::session::Session;

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
        user_awareness.add_reminder(reminder.clone());
      })
      .await;
    self
      .collab_interact
      .read()
      .await
      .add_reminder(reminder)
      .await?;
    Ok(())
  }

  /// Removes a specific reminder for the user by its id
  ///
  pub async fn remove_reminder(&self, reminder_id: &str) -> FlowyResult<()> {
    self
      .with_awareness((), |user_awareness| {
        user_awareness.remove_reminder(reminder_id);
      })
      .await;
    self
      .collab_interact
      .read()
      .await
      .remove_reminder(reminder_id)
      .await?;
    Ok(())
  }

  /// Updates an existing reminder
  ///
  pub async fn update_reminder(&self, reminder_pb: ReminderPB) -> FlowyResult<()> {
    let reminder = Reminder::from(reminder_pb);
    self
      .with_awareness((), |user_awareness| {
        user_awareness.update_reminder(&reminder.id, |new_reminder| {
          new_reminder.clone_from(&reminder)
        });
      })
      .await;
    self
      .collab_interact
      .read()
      .await
      .update_reminder(reminder)
      .await?;

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

  pub async fn initialize_user_awareness(&self, session: &Session) {
    match self.try_initial_user_awareness(session).await {
      Ok(_) => {},
      Err(e) => error!("Failed to initialize user awareness: {:?}", e),
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
  #[instrument(level = "info", skip(self, session), err)]
  pub(crate) async fn try_initial_user_awareness(&self, session: &Session) -> FlowyResult<()> {
    if self.is_loading_awareness.swap(true, Ordering::SeqCst) {
      return Ok(());
    }

    if let Some(old_user_awareness) = self.user_awareness.swap(None) {
      //FIXME: this is not thread-safe if invoked multiple times
      debug!("Closing old user awareness");
      old_user_awareness.read().await.close();
    }

    let object_id =
      user_awareness_object_id(&session.user_uuid, &session.user_workspace.id).to_string();
    trace!("Initializing user awareness {}", object_id);
    let collab_db = self.get_collab_db(session.user_id)?;
    let weak_builder = self.collab_builder.clone();
    let cloned_is_loading = self.is_loading_awareness.clone();
    let session = session.clone();
    let workspace_id = session.user_workspace.id.clone();
    if cloned_is_loading.load(Ordering::SeqCst) {
      return Ok(());
    }

    let result = self
      .cloud_services
      .get_user_service()?
      .get_user_awareness_doc_state(session.user_id, &session.user_workspace.id, &object_id)
      .await;

    let awareness = match result {
      Ok(data) => {
        trace!("Get user awareness collab from remote: {}", data.len());
        Self::collab_for_user_awareness(
          &weak_builder,
          &workspace_id,
          session.user_id,
          &object_id,
          collab_db,
          DataSource::DocStateV1(data),
          None,
        )?
      },
      Err(err) => {
        if err.is_record_not_found() {
          info!("User awareness not found, creating new");
          Self::collab_for_user_awareness(
            &weak_builder,
            &workspace_id,
            session.user_id,
            &object_id,
            collab_db,
            DataSource::Disk,
            None,
          )?
        } else {
          error!("Failed to fetch user awareness: {:?}", err);
          return Err(err);
        }
      },
    };

    self.user_awareness.store(Some(awareness));
    trace!("User awareness initialized");

    // mark the user awareness as not loading
    self.is_loading_awareness.store(false, Ordering::SeqCst);

    Ok(())
  }

  /// Creates a collaboration instance tailored for user awareness.
  ///
  /// This function constructs a collaboration instance based on the given session and raw data,
  /// using a collaboration builder. This instance is specifically geared towards handling
  /// user awareness.
  fn collab_for_user_awareness(
    collab_builder: &Weak<AppFlowyCollabBuilder>,
    workspace_id: &str,
    uid: i64,
    object_id: &str,
    collab_db: Weak<CollabKVDB>,
    doc_state: DataSource,
    notifier: Option<UserAwarenessNotifier>,
  ) -> Result<Arc<RwLock<UserAwareness>>, FlowyError> {
    let collab_builder = collab_builder.upgrade().ok_or(FlowyError::new(
      ErrorCode::Internal,
      "Unexpected error: collab builder is not available",
    ))?;
    let collab_object =
      collab_builder.collab_object(workspace_id, uid, object_id, CollabType::UserAwareness)?;
    let collab = collab_builder
      .create_user_awareness(
        collab_object,
        doc_state,
        collab_db,
        CollabBuilderConfig::default().sync_enable(true),
        notifier,
      )
      .context("Build collab for user awareness failed")?;
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
    F: FnOnce(&mut UserAwareness) -> Output,
  {
    match self.user_awareness.load_full() {
      None => {
        if let Ok(session) = self.get_session() {
          self.initialize_user_awareness(&session).await;
        }
        default_value
      },
      Some(lock) => {
        let mut user_awareness = lock.write().await;
        f(&mut user_awareness)
      },
    }
  }
}

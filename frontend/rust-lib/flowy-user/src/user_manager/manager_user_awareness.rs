use std::sync::{Arc, Weak};

use anyhow::Context;
use collab::core::collab::DataSource;
use collab::lock::RwLock;
use collab_entity::reminder::Reminder;
use collab_entity::CollabType;
use collab_integrate::collab_builder::{
  AppFlowyCollabBuilder, CollabBuilderConfig, KVDBCollabPersistenceImpl,
};
use collab_user::core::{UserAwareness, UserAwarenessNotifier};
use dashmap::try_result::TryResult;
use tracing::{error, info, instrument, trace};

use collab_integrate::CollabKVDB;
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_user_pub::entities::{user_awareness_object_id, Authenticator};

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
      .mut_awareness(|user_awareness| {
        user_awareness.add_reminder(reminder.clone());
      })
      .await?;
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
      .mut_awareness(|user_awareness| {
        user_awareness.remove_reminder(reminder_id);
      })
      .await?;
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
      .mut_awareness(|user_awareness| {
        user_awareness.update_reminder(&reminder.id, |new_reminder| {
          new_reminder.clone_from(&reminder)
        });
      })
      .await?;
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
    let reminders = self
      .mut_awareness(|user_awareness| user_awareness.get_all_reminders())
      .await;
    reminders.unwrap_or_default()
  }

  /// Init UserAwareness for user
  /// 1. check if user awareness exists on disk. If yes init awareness from disk
  /// 2. If not, init awareness from server.
  #[instrument(level = "info", skip(self, session), err)]
  pub(crate) async fn initial_user_awareness(
    &self,
    session: &Session,
    authenticator: &Authenticator,
  ) -> FlowyResult<()> {
    let authenticator = authenticator.clone();
    let object_id =
      user_awareness_object_id(&session.user_uuid, &session.user_workspace.id).to_string();

    // Try to acquire mutable access to `is_loading_awareness`.
    // Thread-safety is ensured by DashMap
    let should_init = match self.is_loading_awareness.try_get_mut(&object_id) {
      TryResult::Present(mut is_loading) => {
        if *is_loading {
          false
        } else {
          *is_loading = true;
          true
        }
      },
      TryResult::Absent => true,
      TryResult::Locked => {
        return Err(FlowyError::new(
          ErrorCode::Internal,
          format!(
            "Failed to lock is_loading_awareness for object: {}",
            object_id
          ),
        ));
      },
    };

    if should_init {
      if let Some(old_user_awareness) = self.user_awareness.swap(None) {
        info!("Closing previous user awareness");
        old_user_awareness.read().await.close(); // Ensure that old awareness is closed
      }

      let is_exist_on_disk = self
        .authenticate_user
        .is_collab_on_disk(session.user_id, &object_id)?;
      if authenticator.is_local() || is_exist_on_disk {
        trace!(
          "Initializing new user awareness from disk:{}, {:?}",
          object_id,
          authenticator
        );
        let collab_db = self.get_collab_db(session.user_id)?;
        let doc_state =
          KVDBCollabPersistenceImpl::new(collab_db.clone(), session.user_id).into_data_source();
        let awareness = Self::collab_for_user_awareness(
          &self.collab_builder.clone(),
          &session.user_workspace.id,
          session.user_id,
          &object_id,
          collab_db,
          doc_state,
          None,
        )?;
        info!("User awareness initialized successfully");
        self.user_awareness.store(Some(awareness));
        if let Some(mut is_loading) = self.is_loading_awareness.get_mut(&object_id) {
          *is_loading = false;
        }
      } else {
        info!(
          "Initializing new user awareness from server:{}, {:?}",
          object_id, authenticator
        );
        self.load_awareness_from_server(session, object_id, authenticator.clone())?;
      }
    } else {
      return Err(FlowyError::new(
        ErrorCode::Internal,
        format!(
          "User awareness is already being loaded for object: {}",
          object_id
        ),
      ));
    }

    Ok(())
  }

  /// Initialize UserAwareness from server.
  /// It will spawn a task in the background in order to no block the caller. This functions is
  /// designed to be thread safe.
  fn load_awareness_from_server(
    &self,
    session: &Session,
    object_id: String,
    authenticator: Authenticator,
  ) -> FlowyResult<()> {
    // Clone necessary data
    let session = session.clone();
    let collab_db = self.get_collab_db(session.user_id)?;
    let weak_builder = self.collab_builder.clone();
    let user_awareness = Arc::downgrade(&self.user_awareness);
    let cloud_services = self.cloud_services.clone();
    let authenticate_user = self.authenticate_user.clone();
    let is_loading_awareness = self.is_loading_awareness.clone();

    // Spawn an async task to fetch or create user awareness
    tokio::spawn(async move {
      let set_is_loading_false = || {
        if let Some(mut is_loading) = is_loading_awareness.get_mut(&object_id) {
          *is_loading = false;
        }
      };

      let create_awareness = if authenticator.is_local() {
        let doc_state =
          KVDBCollabPersistenceImpl::new(collab_db.clone(), session.user_id).into_data_source();
        Self::collab_for_user_awareness(
          &weak_builder,
          &session.user_workspace.id,
          session.user_id,
          &object_id,
          collab_db,
          doc_state,
          None,
        )
      } else {
        let result = cloud_services
          .get_user_service()?
          .get_user_awareness_doc_state(session.user_id, &session.user_workspace.id, &object_id)
          .await;

        match result {
          Ok(data) => {
            trace!("Fetched user awareness collab from remote: {}", data.len());
            Self::collab_for_user_awareness(
              &weak_builder,
              &session.user_workspace.id,
              session.user_id,
              &object_id,
              collab_db,
              DataSource::DocStateV1(data),
              None,
            )
          },
          Err(err) => {
            if err.is_record_not_found() {
              info!("User awareness not found, creating new");
              let doc_state = KVDBCollabPersistenceImpl::new(collab_db.clone(), session.user_id)
                .into_data_source();
              Self::collab_for_user_awareness(
                &weak_builder,
                &session.user_workspace.id,
                session.user_id,
                &object_id,
                collab_db,
                doc_state,
                None,
              )
            } else {
              Err(err)
            }
          },
        }
      };

      match create_awareness {
        Ok(new_user_awareness) => {
          // Validate session before storing the awareness
          if let Ok(current_session) = authenticate_user.get_session() {
            if current_session.user_workspace.id == session.user_workspace.id {
              if let Some(user_awareness) = user_awareness.upgrade() {
                info!("User awareness initialized successfully");
                user_awareness.store(Some(new_user_awareness));
              } else {
                error!("Failed to upgrade user awareness");
              }
            } else {
              info!("User awareness is outdated, ignoring");
            }
          }
          set_is_loading_false();
          Ok(())
        },
        Err(err) => {
          error!("Error while creating user awareness: {:?}", err);
          set_is_loading_false();
          Err(err)
        },
      }
    });
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
  async fn mut_awareness<F, Output>(&self, f: F) -> FlowyResult<Output>
  where
    F: FnOnce(&mut UserAwareness) -> Output,
  {
    match self.user_awareness.load_full() {
      None => {
        info!("User awareness is not loaded when trying to access it");

        let session = self.get_session()?;
        let object_id =
          user_awareness_object_id(&session.user_uuid, &session.user_workspace.id).to_string();
        let is_loading = self
          .is_loading_awareness
          .get(&object_id)
          .map(|r| *r.value())
          .unwrap_or(false);

        if !is_loading {
          let user_profile = self.get_user_profile_from_disk(session.user_id).await?;
          self
            .initial_user_awareness(&session, &user_profile.authenticator)
            .await?;
        }

        Err(FlowyError::new(
          ErrorCode::InProgress,
          "User awareness is loading",
        ))
      },
      Some(lock) => {
        let mut user_awareness = lock.write().await;
        Ok(f(&mut user_awareness))
      },
    }
  }
}

use std::sync::{Arc, Weak};

use anyhow::Context;
use collab::core::collab::DataSource;
use collab::lock::RwLock;
use collab_entity::reminder::Reminder;
use collab_entity::CollabType;
use collab_integrate::collab_builder::{
  AppFlowyCollabBuilder, CollabBuilderConfig, CollabPersistenceImpl,
};
use collab_integrate::CollabKVDB;
use collab_user::core::{UserAwareness, UserAwarenessNotifier};
use dashmap::try_result::TryResult;
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_user_pub::entities::{user_awareness_object_id, WorkspaceType};
use tracing::{error, info, instrument, trace};
use uuid::Uuid;

use crate::entities::ReminderPB;
use crate::notification::{send_notification, UserNotification};
use crate::user_manager::UserManager;

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
    let workspace_id = self.workspace_id()?;
    let awareness = self.get_awareness(&workspace_id).await?;
    awareness.write().await.add_reminder(reminder.clone());

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
    let workspace_id = self.workspace_id()?;
    self
      .get_awareness(&workspace_id)
      .await?
      .write()
      .await
      .remove_reminder(reminder_id);

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
    let workspace_id = self.workspace_id()?;
    let reminder = Reminder::from(reminder_pb);
    self
      .get_awareness(&workspace_id)
      .await?
      .write()
      .await
      .update_reminder(&reminder.id, |update| {
        update
          .set_object_id(&reminder.object_id)
          .set_title(&reminder.title)
          .set_message(&reminder.message)
          .set_is_ack(reminder.is_ack)
          .set_is_read(reminder.is_read)
          .set_scheduled_at(reminder.scheduled_at)
          .set_type(reminder.ty)
          .set_meta(reminder.meta.clone().into_inner());
      });

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
  pub async fn get_all_reminders(&self) -> FlowyResult<Vec<Reminder>> {
    let workspace_id = self.workspace_id()?;
    Ok(
      self
        .get_awareness(&workspace_id)
        .await?
        .read()
        .await
        .get_all_reminders(),
    )
  }

  /// Init UserAwareness for user
  /// 1. check if user awareness exists on disk. If yes init awareness from disk
  /// 2. If not, init awareness from server.
  #[instrument(level = "info", skip(self), err)]
  pub(crate) async fn initial_user_awareness(
    &self,
    uid: i64,
    user_uuid: &Uuid,
    workspace_id: &Uuid,
    workspace_type: &WorkspaceType,
  ) -> FlowyResult<()> {
    let object_id = user_awareness_object_id(user_uuid, &workspace_id.to_string());

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
      let is_exist_on_disk = self
        .authenticate_user
        .is_collab_on_disk(uid, &object_id.to_string())?;
      if workspace_type.is_local() || is_exist_on_disk {
        trace!(
          "Initializing new user awareness from disk:{}, {:?}",
          object_id,
          workspace_type
        );
        let collab_db = self.get_collab_db(uid)?;
        let doc_state =
          CollabPersistenceImpl::new(collab_db.clone(), uid, *workspace_id).into_data_source();
        let awareness = Self::collab_for_user_awareness(
          &self.collab_builder.clone(),
          workspace_id,
          uid,
          &object_id,
          collab_db,
          doc_state,
          None,
        )
        .await?;
        info!("User awareness initialized successfully");
        self
          .user_awareness_by_workspace
          .insert(*workspace_id, awareness);
        if let Some(mut is_loading) = self.is_loading_awareness.get_mut(&object_id) {
          *is_loading = false;
        }
      } else {
        info!(
          "Initializing new user awareness from server:{}, {:?}",
          object_id, workspace_type
        );
        self.load_awareness_from_server(uid, workspace_id, object_id, *workspace_type)?;
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
    uid: i64,
    workspace_id: &Uuid,
    object_id: Uuid,
    workspace_type: WorkspaceType,
  ) -> FlowyResult<()> {
    // Clone necessary data
    let collab_db = self.get_collab_db(uid)?;
    let weak_builder = self.collab_builder.clone();
    let user_awareness = self.user_awareness_by_workspace.clone();
    let cloud_services = self.cloud_service()?;
    let is_loading_awareness = self.is_loading_awareness.clone();
    let workspace_id = *workspace_id;

    // Spawn an async task to fetch or create user awareness
    tokio::spawn(async move {
      let set_is_loading_false = || {
        if let Some(mut is_loading) = is_loading_awareness.get_mut(&object_id) {
          *is_loading = false;
        }
      };

      let create_awareness = if workspace_type.is_local() {
        let doc_state =
          CollabPersistenceImpl::new(collab_db.clone(), uid, workspace_id).into_data_source();
        Self::collab_for_user_awareness(
          &weak_builder,
          &workspace_id,
          uid,
          &object_id,
          collab_db,
          doc_state,
          None,
        )
        .await
      } else {
        let result = cloud_services
          .get_user_service()?
          .get_user_awareness_doc_state(uid, &workspace_id, &object_id)
          .await;

        match result {
          Ok(data) => {
            trace!("Fetched user awareness collab from remote: {}", data.len());
            Self::collab_for_user_awareness(
              &weak_builder,
              &workspace_id,
              uid,
              &object_id,
              collab_db,
              DataSource::DocStateV1(data),
              None,
            )
            .await
          },
          Err(err) => {
            if err.is_record_not_found() {
              info!("User awareness not found, creating new");
              let doc_state =
                CollabPersistenceImpl::new(collab_db.clone(), uid, workspace_id).into_data_source();
              Self::collab_for_user_awareness(
                &weak_builder,
                &workspace_id,
                uid,
                &object_id,
                collab_db,
                doc_state,
                None,
              )
              .await
            } else {
              Err(err)
            }
          },
        }
      };

      match create_awareness {
        Ok(new_user_awareness) => {
          user_awareness.insert(workspace_id, new_user_awareness);
          send_notification(
            &workspace_id.to_string(),
            UserNotification::DidLoadUserAwareness,
          );

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
  async fn collab_for_user_awareness(
    collab_builder: &Weak<AppFlowyCollabBuilder>,
    workspace_id: &Uuid,
    uid: i64,
    object_id: &Uuid,
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
      .await
      .context("Build collab for user awareness failed")?;
    Ok(collab)
  }

  async fn get_awareness(&self, workspace_id: &Uuid) -> FlowyResult<Arc<RwLock<UserAwareness>>> {
    let awareness = self
      .user_awareness_by_workspace
      .get(workspace_id)
      .map(|v| v.value().clone());
    awareness.ok_or_else(|| FlowyError::internal().with_context("User awareness is not loaded"))
  }
}

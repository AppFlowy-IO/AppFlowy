use std::sync::{Arc, Weak};

use collab_folder::{Folder, FolderNotify, UserId};
use tracing::{event, Level};

use collab_integrate::RocksCollabDB;
use flowy_error::{ErrorCode, FlowyError, FlowyResult};

use crate::manager::{FolderInitDataSource, FolderManager};
use crate::manager_observer::{
  subscribe_folder_snapshot_state_changed, subscribe_folder_sync_state_changed,
  subscribe_folder_trash_changed, subscribe_folder_view_changed,
};
use crate::user_default::DefaultFolderBuilder;
use crate::util::is_exist_in_local_disk;

impl FolderManager {
  /// Called immediately after the application launched if the user already sign in/sign up.
  #[tracing::instrument(level = "info", skip(self, initial_data), err)]
  pub async fn initialize(
    &self,
    uid: i64,
    workspace_id: &str,
    initial_data: FolderInitDataSource,
  ) -> FlowyResult<()> {
    // Update the workspace id
    event!(
      Level::INFO,
      "Init workspace: {} from: {}",
      workspace_id,
      initial_data
    );
    *self.workspace_id.write() = Some(workspace_id.to_string());
    let workspace_id = workspace_id.to_string();

    // Get the collab db for the user with given user id.
    let collab_db = self.user.collab_db(uid)?;

    let (view_tx, view_rx) = tokio::sync::broadcast::channel(100);
    let (section_change_tx, section_change_rx) = tokio::sync::broadcast::channel(100);
    let folder_notifier = FolderNotify {
      view_change_tx: view_tx,
      section_change_tx,
    };

    let folder = match initial_data {
      FolderInitDataSource::LocalDisk {
        create_if_not_exist,
      } => {
        let is_exist = is_exist_in_local_disk(&self.user, &workspace_id).unwrap_or(false);
        if is_exist {
          self
            .open_local_folder(uid, &workspace_id, collab_db, folder_notifier)
            .await?
        } else if create_if_not_exist {
          // Currently, this branch is only used when the server type is supabase. For appflowy cloud,
          // the default workspace is already created when the user sign up.
          self
            .create_default_folder(uid, &workspace_id, collab_db, folder_notifier)
            .await?
        } else {
          return Err(FlowyError::new(
            ErrorCode::RecordNotFound,
            "Can't find any workspace data",
          ));
        }
      },
      FolderInitDataSource::Cloud(raw_data) => {
        if raw_data.is_empty() {
          event!(Level::INFO, "remote folder data is empty, open from local");
          self
            .open_local_folder(uid, &workspace_id, collab_db, folder_notifier)
            .await?
        } else {
          event!(Level::INFO, "Restore folder with remote data");
          let collab = self
            .collab_for_folder(uid, &workspace_id, collab_db.clone(), raw_data)
            .await?;
          Folder::open(UserId::from(uid), collab, Some(folder_notifier.clone()))?
        }
      },
      FolderInitDataSource::FolderData(folder_data) => {
        event!(Level::INFO, "Restore folder with passed-in folder data");
        let collab = self
          .collab_for_folder(uid, &workspace_id, collab_db, vec![])
          .await?;
        Folder::create(
          UserId::from(uid),
          collab,
          Some(folder_notifier),
          folder_data,
        )
      },
    };

    let folder_state_rx = folder.subscribe_sync_state();
    *self.mutex_folder.lock() = Some(folder);

    let weak_mutex_folder = Arc::downgrade(&self.mutex_folder);
    subscribe_folder_sync_state_changed(workspace_id.clone(), folder_state_rx, &weak_mutex_folder);
    subscribe_folder_snapshot_state_changed(workspace_id, &weak_mutex_folder);
    subscribe_folder_trash_changed(section_change_rx, &weak_mutex_folder);
    subscribe_folder_view_changed(view_rx, &weak_mutex_folder);
    Ok(())
  }

  async fn create_default_folder(
    &self,
    uid: i64,
    workspace_id: &str,
    collab_db: Weak<RocksCollabDB>,
    folder_notifier: FolderNotify,
  ) -> Result<Folder, FlowyError> {
    event!(Level::INFO, "Create folder with default folder builder");
    let folder_data =
      DefaultFolderBuilder::build(uid, workspace_id.to_string(), &self.operation_handlers).await;
    let collab = self
      .collab_for_folder(uid, workspace_id, collab_db, vec![])
      .await?;
    Ok(Folder::create(
      UserId::from(uid),
      collab,
      Some(folder_notifier),
      folder_data,
    ))
  }

  async fn open_local_folder(
    &self,
    uid: i64,
    workspace_id: &str,
    collab_db: Weak<RocksCollabDB>,
    folder_notifier: FolderNotify,
  ) -> Result<Folder, FlowyError> {
    event!(Level::INFO, "Init folder from local disk");
    let collab = self
      .collab_for_folder(uid, workspace_id, collab_db, vec![])
      .await?;
    let folder = Folder::open(UserId::from(uid), collab, Some(folder_notifier))?;
    Ok(folder)
  }
}

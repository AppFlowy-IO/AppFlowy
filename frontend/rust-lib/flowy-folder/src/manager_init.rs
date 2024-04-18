use collab_entity::CollabType;

use collab_folder::{Folder, FolderNotify, UserId};
use tokio::task::spawn_blocking;
use tracing::{event, Level};

use collab_integrate::CollabKVDB;

use flowy_error::{FlowyError, FlowyResult};

use collab::core::collab::DataSource;
use std::sync::{Arc, Weak};

use crate::manager::{FolderInitDataSource, FolderManager};
use crate::manager_observer::{
  subscribe_folder_snapshot_state_changed, subscribe_folder_sync_state_changed,
  subscribe_folder_trash_changed, subscribe_folder_view_changed,
};
use crate::user_default::DefaultFolderBuilder;

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
        let is_exist = self.is_workspace_exist_in_local(uid, &workspace_id).await;
        // 1. if the folder exists, open it from local disk
        if is_exist {
          event!(Level::INFO, "Init folder from local disk");
          self
            .make_folder(
              uid,
              &workspace_id,
              collab_db,
              DataSource::Disk,
              folder_notifier,
            )
            .await?
        } else if create_if_not_exist {
          // 2. if the folder doesn't exist and create_if_not_exist is true, create a default folder
          // Currently, this branch is only used when the server type is supabase. For appflowy cloud,
          // the default workspace is already created when the user sign up.
          self
            .create_default_folder(uid, &workspace_id, collab_db, folder_notifier)
            .await?
        } else {
          // 3. If the folder doesn't exist and create_if_not_exist is false, try to fetch the folder data from cloud/
          // This will happen user can't fetch the folder data when the user sign in.
          let doc_state = self
            .cloud_service
            .get_folder_doc_state(&workspace_id, uid, CollabType::Folder, &workspace_id)
            .await?;

          self
            .make_folder(
              uid,
              &workspace_id,
              collab_db.clone(),
              DataSource::DocStateV1(doc_state),
              folder_notifier.clone(),
            )
            .await?
        }
      },
      FolderInitDataSource::Cloud(doc_state) => {
        if doc_state.is_empty() {
          event!(Level::ERROR, "remote folder data is empty, open from local");
          self
            .make_folder(
              uid,
              &workspace_id,
              collab_db,
              DataSource::Disk,
              folder_notifier,
            )
            .await?
        } else {
          event!(Level::INFO, "Restore folder from remote data");
          self
            .make_folder(
              uid,
              &workspace_id,
              collab_db.clone(),
              DataSource::DocStateV1(doc_state),
              folder_notifier.clone(),
            )
            .await?
        }
      },
      FolderInitDataSource::FolderData(folder_data) => {
        event!(Level::INFO, "Restore folder with passed-in folder data");
        let collab = self
          .create_empty_collab(uid, &workspace_id, collab_db)
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
    let index_content_rx = folder.subscribe_index_content();
    self
      .folder_indexer
      .set_index_content_receiver(index_content_rx, workspace_id.clone());

    // Index all views in the folder if needed
    if !self.folder_indexer.is_indexed() {
      let views = folder.get_all_views_recursively();
      let folder_indexer = self.folder_indexer.clone();

      // We spawn a blocking task to index all views in the folder
      let wid = workspace_id.clone();
      spawn_blocking(move || {
        folder_indexer.index_all_views(views, wid);
      });
    }

    *self.mutex_folder.lock() = Some(folder);

    let weak_mutex_folder = Arc::downgrade(&self.mutex_folder);
    subscribe_folder_sync_state_changed(workspace_id.clone(), folder_state_rx, &weak_mutex_folder);
    subscribe_folder_snapshot_state_changed(workspace_id, &weak_mutex_folder);
    subscribe_folder_trash_changed(section_change_rx, &weak_mutex_folder);
    subscribe_folder_view_changed(view_rx, &weak_mutex_folder);
    Ok(())
  }

  async fn is_workspace_exist_in_local(&self, uid: i64, workspace_id: &str) -> bool {
    if let Ok(weak_collab) = self.user.collab_db(uid) {
      if let Some(collab_db) = weak_collab.upgrade() {
        return collab_db.is_exist(uid, workspace_id).await.unwrap_or(false);
      }
    }
    false
  }

  async fn create_default_folder(
    &self,
    uid: i64,
    workspace_id: &str,
    collab_db: Weak<CollabKVDB>,
    folder_notifier: FolderNotify,
  ) -> Result<Folder, FlowyError> {
    event!(
      Level::INFO,
      "Create folder:{} with default folder builder",
      workspace_id
    );
    let folder_data =
      DefaultFolderBuilder::build(uid, workspace_id.to_string(), &self.operation_handlers).await;
    let collab = self
      .create_empty_collab(uid, workspace_id, collab_db)
      .await?;
    Ok(Folder::create(
      UserId::from(uid),
      collab,
      Some(folder_notifier),
      folder_data,
    ))
  }
}

use crate::manager::{FolderInitDataSource, FolderManager};
use crate::manager_observer::*;
use crate::user_default::DefaultFolderBuilder;
use collab::core::collab::DataSource;
use collab_entity::{CollabType, EncodedCollab};
use collab_folder::{Folder, FolderNotify, UserId};
use collab_integrate::CollabKVDB;
use flowy_error::{FlowyError, FlowyResult};
use std::sync::{Arc, Weak};
use tokio::task::spawn_blocking;
use tracing::{event, info, Level};

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

    if let Some(old_folder) = self.mutex_folder.write().await.take() {
      old_folder.close();
      info!(
        "remove old folder: {}",
        old_folder.get_workspace_id().unwrap_or_default()
      );
    }

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
    };

    let folder_state_rx = folder.subscribe_sync_state();
    let index_content_rx = folder.subscribe_index_content();
    self
      .folder_indexer
      .set_index_content_receiver(index_content_rx, workspace_id.clone());
    self.handle_index_folder(workspace_id.clone(), &folder);

    *self.mutex_folder.write() = Some(folder);

    let weak_mutex_folder = Arc::downgrade(&self.mutex_folder);
    subscribe_folder_sync_state_changed(
      workspace_id.clone(),
      folder_state_rx,
      Arc::downgrade(&self.user),
    );
    subscribe_folder_snapshot_state_changed(
      workspace_id.clone(),
      &weak_mutex_folder,
      Arc::downgrade(&self.user),
    );
    subscribe_folder_trash_changed(
      workspace_id.clone(),
      section_change_rx,
      &weak_mutex_folder,
      Arc::downgrade(&self.user),
    );
    subscribe_folder_view_changed(
      workspace_id.clone(),
      view_rx,
      &weak_mutex_folder,
      Arc::downgrade(&self.user),
    );

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
    Ok(Folder::open_with(
      UserId::from(uid),
      collab,
      Some(folder_notifier),
      Some(folder_data),
    ))
  }

  fn handle_index_folder(&self, workspace_id: String, folder: &Folder) {
    let mut index_all = true;

    let encoded_collab = self
      .store_preferences
      .get_object::<EncodedCollab>(&workspace_id);

    if let Some(encoded_collab) = encoded_collab {
      if let Ok(changes) = folder.calculate_view_changes(encoded_collab) {
        let folder_indexer = self.folder_indexer.clone();

        let views = folder.get_all_views();
        let wid = workspace_id.clone();

        if !changes.is_empty() && !views.is_empty() {
          spawn_blocking(move || {
            // We index the changes
            folder_indexer.index_view_changes(views, changes, wid);
          });
          index_all = false;
        }
      }
    }

    if index_all {
      let views = folder.get_all_views();
      let folder_indexer = self.folder_indexer.clone();
      let wid = workspace_id.clone();

      // We spawn a blocking task to index all views in the folder
      spawn_blocking(move || {
        // We remove old indexes just in case
        let _ = folder_indexer.remove_indices_for_workspace(wid.clone());

        // We index all views from the workspace
        folder_indexer.index_all_views(views, wid);
      });
    }

    self.save_collab_to_preferences(folder);
  }

  fn save_collab_to_preferences(&self, folder: &Folder) {
    if let Some(workspace_id) = folder.get_workspace_id() {
      let encoded_collab = folder.encode_collab();

      if let Ok(encoded) = encoded_collab {
        let _ = self.store_preferences.set_object(&workspace_id, encoded);
      }
    }
  }
}

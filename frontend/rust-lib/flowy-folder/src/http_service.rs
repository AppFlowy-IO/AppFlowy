use crate::entities::FolderPageNotificationPayloadPB;
use crate::manager::FolderManager;
use crate::notification::{send_folder_notification, FolderNotification};
use crate::services::sqlite_sql::folder_page_sql::{
  get_page_by_id, upsert_folder_view_with_children,
};
use crate::sync_worker::sync_worker_page_ops::SyncWorkerPageOps;
use crate::sync_worker::sync_worker_space_ops::SyncWorkerSpaceOps;

use async_trait::async_trait;
use client_api::entity::workspace_dto::{
  CreatePageParams, CreateSpaceParams, DuplicatePageParams, FavoriteFolderView, FavoritePageParams,
  FolderView, MovePageParams, RecentFolderView, TrashFolderView, UpdatePageParams,
  UpdateSpaceParams,
};
use flowy_error::{FlowyError, FlowyResult};
use tracing::{error, info};

#[async_trait]
pub trait FolderHttpService {
  /// Get the workspace folder
  ///
  /// It will try to get the data from the local database first, if the data is not found, it will try to get the data from the cloud service.
  ///
  /// # Arguments
  /// * `workspace_id` - The id of the workspace
  /// * `depth` - The depth of the folder, default is 10. If you only need to get the spaces, you can set the depth to 1.
  /// * `root_view_id` - The id of the root view, default is the workspace id.
  ///
  /// # Returns
  /// * `FolderView` - The workspace folder
  async fn get_workspace_folder(
    &self,
    workspace_id: &str,
    depth: Option<u32>,
    root_view_id: Option<String>,
  ) -> FlowyResult<FolderView>;

  /// Create a new page
  ///
  /// # Arguments
  /// * `workspace_id` - The id of the workspace
  /// * `params` - The params of the page
  ///
  /// # Returns
  /// * `()` - The result of the operation
  async fn create_page(&self, workspace_id: &str, params: CreatePageParams) -> FlowyResult<()>;

  /// Update a page
  ///
  /// # Arguments
  /// * `workspace_id` - The id of the workspace
  /// * `view_id` - The id of the view
  /// * `params` - The params of the page
  ///
  /// # Returns
  /// * `()` - The result of the operation
  async fn update_page(
    &self,
    workspace_id: &str,
    view_id: &str,
    params: UpdatePageParams,
  ) -> FlowyResult<()>;

  /// Move a page to the trash
  ///
  /// Notes: Move a page the trash doesn't mean delete the page, you can still restore it from the trash.
  ///
  /// # Arguments
  /// * `workspace_id` - The id of the workspace
  /// * `view_id` - The id of the view
  ///
  /// # Returns
  async fn move_page_to_trash(&self, workspace_id: &str, view_id: &str) -> FlowyResult<()>;

  /// Restore a page from the trash
  ///
  /// # Arguments
  /// * `workspace_id` - The id of the workspace
  /// * `view_id` - The id of the view
  ///
  /// # Returns
  /// * `()` - The result of the operation
  async fn restore_page_from_trash(&self, workspace_id: &str, view_id: &str) -> FlowyResult<()>;

  /// Duplicate a page
  ///
  /// # Arguments
  /// * `workspace_id` - The id of the workspace
  /// * `view_id` - The id of the view
  /// * `params` - The params of the page
  ///
  /// # Returns
  /// * `()` - The result of the operation
  async fn duplicate_page(
    &self,
    workspace_id: &str,
    view_id: &str,
    params: DuplicatePageParams,
  ) -> FlowyResult<()>;

  /// Move a page to another page
  ///
  /// # Arguments
  /// * `workspace_id` - The id of the workspace
  /// * `view_id` - The id of the view
  /// * `params` - The params of the page
  ///
  /// # Returns
  async fn move_page(
    &self,
    workspace_id: &str,
    view_id: &str,
    params: MovePageParams,
  ) -> FlowyResult<()>;

  /// Create a new space
  ///
  /// # Arguments
  /// * `workspace_id` - The id of the workspace
  /// * `params` - The params of the space
  ///
  /// # Returns
  /// * `()` - The result of the operation
  async fn create_space(&self, workspace_id: &str, params: CreateSpaceParams) -> FlowyResult<()>;

  /// Update a space
  ///
  /// # Arguments
  /// * `workspace_id` - The id of the workspace
  /// * `space_id` - The id of the space
  /// * `params` - The params of the space
  ///
  /// # Returns
  /// * `()` - The result of the operation
  async fn update_space(
    &self,
    workspace_id: &str,
    space_id: &str,
    params: UpdateSpaceParams,
  ) -> FlowyResult<()>;

  /// Get the favorite pages
  ///
  /// # Arguments
  /// * `workspace_id` - The id of the workspace
  ///
  /// # Returns
  /// * `Vec<FavoriteFolderView>` - The favorite pages
  async fn get_favorite_pages(
    &self,
    workspace_id: &str,
  ) -> Result<Vec<FavoriteFolderView>, FlowyError>;

  /// Update a favorite page
  ///
  /// # Arguments
  /// * `workspace_id` - The id of the workspace
  /// * `view_id` - The id of the view
  /// * `params` - The params of the favorite page
  ///
  /// # Returns
  /// * `()` - The result of the operation
  async fn update_favorite_page(
    &self,
    workspace_id: &str,
    view_id: &str,
    params: FavoritePageParams,
  ) -> Result<(), FlowyError>;

  /// Get the recent pages
  ///
  /// # Arguments
  /// * `workspace_id` - The id of the workspace
  ///
  /// # Returns
  /// * `Vec<RecentFolderView>` - The recent pages
  async fn get_recent_pages(&self, workspace_id: &str)
    -> Result<Vec<RecentFolderView>, FlowyError>;

  /// Get the trash pages
  ///
  /// # Arguments
  /// * `workspace_id` - The id of the workspace
  ///
  /// # Returns
  /// * `Vec<TrashFolderView>` - The trash pages
  async fn get_trash_pages(&self, workspace_id: &str) -> Result<Vec<TrashFolderView>, FlowyError>;
}

#[async_trait]
impl FolderHttpService for FolderManager {
  /// This function will try to return the data from the local database first,
  ///   if the data is not found, it will try to fetch the data from the cloud service.
  ///
  /// # Workflow
  /// 1. try to get the data from the local database.
  /// 2. Fetch data from cloud service in the background and persist it
  /// 3. Return local data if available, otherwise return error
  async fn get_workspace_folder(
    &self,
    workspace_id: &str,
    depth: Option<u32>,
    root_view_id: Option<String>,
  ) -> FlowyResult<FolderView> {
    // 1. try to get the data from the local database.
    let uid = self.user.user_id()?;
    let mut conn = self.user.sqlite_connection(uid)?;
    let local_folder_view = get_page_by_id(
      &mut conn,
      workspace_id,
      root_view_id.as_deref().unwrap_or(workspace_id),
      depth,
      true,
    );

    // 2. Fetch data from cloud service in the background and persist it
    let cloud_root_view_id = root_view_id.clone();
    let cloud_workspace_id = workspace_id.to_string();
    let user = self.user.clone();
    let cloud_service = self.cloud_service.clone();
    tokio::spawn(async move {
      if let Ok(folder_view) = cloud_service
        .get_workspace_folder(&cloud_workspace_id, depth, cloud_root_view_id)
        .await
      {
        // Save the data to the local database
        if let Ok(mut conn) = user.sqlite_connection(uid) {
          let parent_view_id = folder_view.parent_view_id.clone();
          let length = upsert_folder_view_with_children(
            &mut conn,
            folder_view.clone(),
            &cloud_workspace_id,
            Some(parent_view_id),
          );

          match length {
            Ok(length) => {
              info!(
                "[Folder] update workspace folder: {:?}, length: {}",
                folder_view, length
              );

              // when the folder is updated, send the notification to the client
              send_folder_notification(
                &cloud_workspace_id,
                FolderNotification::DidUpdateFolderPages,
                FolderPageNotificationPayloadPB {
                  workspace_id: cloud_workspace_id.to_string(),
                  folder_view: folder_view.into(),
                },
              );
            },
            Err(err) => {
              error!("[Folder] update workspace folder failed: {:?}", err);
            },
          }
        }
      }
    });

    // 3. Return local data if available, otherwise return error
    match local_folder_view {
      Ok(folder_view) => Ok(folder_view),
      Err(err) => Err(err),
    }
  }

  /// Create a new page and persist it to the local database
  ///
  /// # Workflow
  /// 1. Create a new page in the cloud service
  /// 2. Persist the page to the local database
  /// 3. Return the result
  async fn create_page(&self, workspace_id: &str, params: CreatePageParams) -> FlowyResult<()> {
    self.sync_worker.create_page(workspace_id, params).await
  }

  async fn update_page(
    &self,
    workspace_id: &str,
    view_id: &str,
    params: UpdatePageParams,
  ) -> FlowyResult<()> {
    self
      .sync_worker
      .update_page(workspace_id, view_id, params)
      .await
  }

  async fn move_page_to_trash(&self, workspace_id: &str, view_id: &str) -> FlowyResult<()> {
    self
      .sync_worker
      .move_page_to_trash(workspace_id, view_id)
      .await
  }

  async fn restore_page_from_trash(&self, workspace_id: &str, view_id: &str) -> FlowyResult<()> {
    self
      .sync_worker
      .restore_page_from_trash(workspace_id, view_id)
      .await?;
    Ok(())
  }

  async fn duplicate_page(
    &self,
    workspace_id: &str,
    view_id: &str,
    params: DuplicatePageParams,
  ) -> FlowyResult<()> {
    self
      .cloud_service
      .duplicate_page(workspace_id, view_id, params)
      .await?;
    Ok(())
  }

  async fn move_page(
    &self,
    workspace_id: &str,
    view_id: &str,
    params: MovePageParams,
  ) -> FlowyResult<()> {
    self
      .sync_worker
      .move_page(workspace_id, view_id, params)
      .await
  }

  async fn create_space(&self, workspace_id: &str, params: CreateSpaceParams) -> FlowyResult<()> {
    self.sync_worker.create_space(workspace_id, params).await
  }

  async fn update_space(
    &self,
    workspace_id: &str,
    space_id: &str,
    params: UpdateSpaceParams,
  ) -> FlowyResult<()> {
    self
      .sync_worker
      .update_space(workspace_id, space_id, params)
      .await
  }

  async fn get_favorite_pages(
    &self,
    workspace_id: &str,
  ) -> Result<Vec<FavoriteFolderView>, FlowyError> {
    let favorite_pages = self.cloud_service.get_favorite_pages(workspace_id).await?;
    Ok(favorite_pages)
  }

  async fn update_favorite_page(
    &self,
    workspace_id: &str,
    view_id: &str,
    params: FavoritePageParams,
  ) -> Result<(), FlowyError> {
    self
      .cloud_service
      .update_favorite_page(workspace_id, view_id, params)
      .await?;
    Ok(())
  }

  async fn get_recent_pages(
    &self,
    workspace_id: &str,
  ) -> Result<Vec<RecentFolderView>, FlowyError> {
    let recent_pages = self.cloud_service.get_recent_pages(workspace_id).await?;
    Ok(recent_pages)
  }

  async fn get_trash_pages(&self, workspace_id: &str) -> Result<Vec<TrashFolderView>, FlowyError> {
    let trash_pages = self.cloud_service.get_trash_pages(workspace_id).await?;
    Ok(trash_pages)
  }
}

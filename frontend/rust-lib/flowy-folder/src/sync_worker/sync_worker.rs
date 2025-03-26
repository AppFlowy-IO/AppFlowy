// This worker is responsible for syncing the data between the local database and the cloud service.
// All the operations using the http service should call this worker to do the sync work.

use std::sync::Arc;
use std::time::Duration;

use client_api::entity::workspace_dto::{
  CreatePageParams, CreateSpaceParams, FolderView, MovePageParams, UpdatePageParams,
  UpdateSpaceParams,
};
use flowy_error::{FlowyError, FlowyResult};
use flowy_folder_pub::cloud::FolderCloudService;
use flowy_sqlite::DBConnection;
use tokio::time;
use tracing::{error, info};

use crate::{
  manager::FolderUser,
  notification::{send_folder_notification, FolderNotification},
  services::sqlite_sql::folder_operation_sql::{
    get_pending_operations_by_workspace_id, update_operation_status, FolderOperation,
  },
};

use super::sync_worker_op_name::{
  CREATE_PAGE_OPERATION_NAME, CREATE_SPACE_OPERATION_NAME, DELETE_PAGE_OPERATION_NAME,
  HTTP_STATUS_COMPLETED, MOVE_PAGE_OPERATION_NAME, MOVE_PAGE_TO_TRASH_OPERATION_NAME,
  RESTORE_PAGE_FROM_TRASH_OPERATION_NAME, UPDATE_PAGE_OPERATION_NAME, UPDATE_SPACE_OPERATION_NAME,
};

#[derive(Clone)]
pub struct SyncWorker {
  /// The cloud service to sync the data with
  pub(crate) cloud_service: Arc<dyn FolderCloudService>,

  /// The user to sync the data with
  pub(crate) user: Arc<dyn FolderUser>,
}

impl SyncWorker {
  pub fn new(cloud_service: Arc<dyn FolderCloudService>, user: Arc<dyn FolderUser>) -> Self {
    Self {
      cloud_service,
      user,
    }
  }

  /// Start a background task to monitor and process pending operations
  pub fn start_operation_monitor(&self, mut conn: DBConnection, workspace_id: String) {
    let cloned_self = self.clone();
    tokio::spawn(async move {
      let mut interval = time::interval(Duration::from_secs(5)); // fixme: use observer instead of interval
      loop {
        interval.tick().await;

        // Get pending operations
        match get_pending_operations_by_workspace_id(&mut conn, &workspace_id) {
          Ok(operations) => {
            if !operations.is_empty() {
              info!("Processing {} pending operations", operations.len());
              for operation in operations {
                let cloned_operation = operation.clone();
                if let Err(e) = cloned_self.process_operation(&mut conn, operation).await {
                  error!("Failed to process operation: {}", e);
                  break;
                } else {
                  info!(
                    "Operation id: {}, name: {} processed successfully",
                    cloned_operation.id, cloned_operation.name
                  );
                }
              }
            } else {
              // If there are no pending operations, send the notification to the client
              send_folder_notification(&workspace_id, FolderNotification::DidSyncPendingOperations);
            }
          },
          Err(e) => {
            error!("Failed to get pending operations: {}", e);
          },
        }
      }
    });
  }

  /// Process a single operation
  async fn process_operation(
    &self,
    conn: &mut DBConnection,
    operation: FolderOperation,
  ) -> FlowyResult<()> {
    match operation.name.as_str() {
      // Page operations
      CREATE_PAGE_OPERATION_NAME => self.create_page_operation(conn, &operation).await,
      UPDATE_PAGE_OPERATION_NAME => self.update_page_operation(conn, &operation).await,
      MOVE_PAGE_OPERATION_NAME => self.move_page_operation(conn, &operation).await,
      #[allow(clippy::match_overlapping_arm)]
      MOVE_PAGE_TO_TRASH_OPERATION_NAME => {
        self.move_page_to_trash_operation(conn, &operation).await
      },
      RESTORE_PAGE_FROM_TRASH_OPERATION_NAME => {
        self
          .restore_page_from_trash_operation(conn, &operation)
          .await
      },
      DELETE_PAGE_OPERATION_NAME => self.delete_page_operation(conn, &operation).await,

      // Space operations
      CREATE_SPACE_OPERATION_NAME => self.create_space_operation(conn, &operation).await,
      UPDATE_SPACE_OPERATION_NAME => self.update_space_operation(conn, &operation).await,

      _ => {
        error!("Unknown operation type: {}", operation.name);
        Ok(())
      },
    }
  }

  pub fn build_update_folder_view(
    &self,
    folder_view: FolderView,
    update_params: UpdatePageParams,
  ) -> FolderView {
    let mut folder_view = folder_view;
    folder_view.name = update_params.name;
    if let Some(icon) = update_params.icon {
      folder_view.icon = Some(icon);
    }
    if let Some(is_locked) = update_params.is_locked {
      folder_view.is_locked = Some(is_locked);
    }
    if let Some(extra) = update_params.extra {
      folder_view.extra = Some(extra);
    }
    folder_view
  }

  pub fn build_moved_folder_view(
    &self,
    folder_view: FolderView,
    move_params: MovePageParams,
  ) -> FolderView {
    let mut folder_view = folder_view;
    folder_view.parent_view_id = move_params.new_parent_view_id;
    folder_view
  }

  pub fn build_update_space_view(
    &self,
    folder_view: FolderView,
    update_params: UpdateSpaceParams,
  ) -> FolderView {
    let mut folder_view = folder_view;
    folder_view.name = update_params.name;
    // TODO: update the space icon and color and permission
    folder_view
  }

  async fn create_page_operation(
    &self,
    conn: &mut DBConnection,
    operation: &FolderOperation,
  ) -> FlowyResult<()> {
    self
      .process_operation_with_payload::<CreatePageParams, _, _>(
        conn,
        operation,
        |params| async move {
          self
            .cloud_service
            .create_page(&operation.workspace_id, params)
            .await
        },
      )
      .await
  }

  async fn update_page_operation(
    &self,
    conn: &mut DBConnection,
    operation: &FolderOperation,
  ) -> FlowyResult<()> {
    if let Some(page_id) = operation.page_id.clone() {
      self
        .process_operation_with_payload::<UpdatePageParams, _, _>(
          conn,
          operation,
          |params| async move {
            self
              .cloud_service
              .update_page(&operation.workspace_id, &page_id, params)
              .await
          },
        )
        .await?;
    }
    Ok(())
  }

  async fn move_page_operation(
    &self,
    conn: &mut DBConnection,
    operation: &FolderOperation,
  ) -> FlowyResult<()> {
    if let Some(page_id) = operation.page_id.clone() {
      self
        .process_operation_with_payload::<MovePageParams, _, _>(
          conn,
          operation,
          |params| async move {
            self
              .cloud_service
              .move_page(&operation.workspace_id, &page_id, params)
              .await
          },
        )
        .await?;
    }
    Ok(())
  }

  async fn move_page_to_trash_operation(
    &self,
    conn: &mut DBConnection,
    operation: &FolderOperation,
  ) -> FlowyResult<()> {
    if let Some(page_id) = operation.page_id.clone() {
      self
        .process_operation_without_payload(conn, operation, || async move {
          self
            .cloud_service
            .move_page_to_trash(&operation.workspace_id, &page_id)
            .await
        })
        .await?;
    }
    Ok(())
  }

  async fn restore_page_from_trash_operation(
    &self,
    conn: &mut DBConnection,
    operation: &FolderOperation,
  ) -> FlowyResult<()> {
    if let Some(page_id) = operation.page_id.clone() {
      self
        .process_operation_without_payload(conn, operation, || async move {
          self
            .cloud_service
            .restore_page_from_trash(&operation.workspace_id, &page_id)
            .await
        })
        .await?;
    }
    Ok(())
  }

  async fn delete_page_operation(
    &self,
    conn: &mut DBConnection,
    operation: &FolderOperation,
  ) -> FlowyResult<()> {
    todo!("Implement delete page operation");
  }

  async fn create_space_operation(
    &self,
    conn: &mut DBConnection,
    operation: &FolderOperation,
  ) -> FlowyResult<()> {
    self
      .process_operation_with_payload::<CreateSpaceParams, _, _>(
        conn,
        operation,
        |params| async move {
          self
            .cloud_service
            .create_space(&operation.workspace_id, params)
            .await
        },
      )
      .await
  }

  async fn update_space_operation(
    &self,
    conn: &mut DBConnection,
    operation: &FolderOperation,
  ) -> FlowyResult<()> {
    self
      .process_operation_with_payload::<UpdateSpaceParams, _, _>(
        conn,
        operation,
        |params| async move {
          match operation.page_id.as_ref() {
            Some(page_id) => {
              self
                .cloud_service
                .update_space(&operation.workspace_id, &page_id, params)
                .await
            },
            None => {
              Err(FlowyError::internal().with_context("Page id is required for update space"))
            },
          }
        },
      )
      .await
  }

  /// Process operations with payload that need to be parsed and sent to cloud service.
  /// If the operation is successful, the operation status will be updated to completed
  async fn process_operation_with_payload<T, F, Fut>(
    &self,
    conn: &mut DBConnection,
    operation: &FolderOperation,
    cloud_operation: F,
  ) -> FlowyResult<()>
  where
    T: serde::de::DeserializeOwned,
    F: FnOnce(T) -> Fut,
    Fut: std::future::Future<Output = FlowyResult<()>>,
  {
    if let Some(payload) = operation.payload.clone() {
      let params: T = serde_json::from_str(&payload)?;
      let result = cloud_operation(params).await;
      match result {
        Ok(_) => {
          update_operation_status(conn, operation.id, HTTP_STATUS_COMPLETED.to_string())?;
        },
        Err(e) => {
          error!(
            "Operation {} failed: {}, payload: {}",
            operation.name, e, payload
          );
          return Err(e);
        },
      }
    }
    Ok(())
  }

  /// Process operations that don't need payload parsing.
  /// If the operation is successful, the operation status will be updated to completed
  async fn process_operation_without_payload<F, Fut>(
    &self,
    conn: &mut DBConnection,
    operation: &FolderOperation,
    cloud_operation: F,
  ) -> FlowyResult<()>
  where
    F: FnOnce() -> Fut,
    Fut: std::future::Future<Output = FlowyResult<()>>,
  {
    let result = cloud_operation().await;
    match result {
      Ok(_) => {
        update_operation_status(conn, operation.id, HTTP_STATUS_COMPLETED.to_string())?;
      },
      Err(e) => {
        error!("Operation {} failed: {}", operation.name, e);
        return Err(e);
      },
    }
    Ok(())
  }
}

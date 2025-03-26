// This worker is responsible for syncing the data between the local database and the cloud service.
// All the operations using the http service should call this worker to do the sync work.

use std::sync::Arc;
use std::time::Duration;

use client_api::entity::workspace_dto::{
  CreatePageParams, FolderView, MovePageParams, UpdatePageParams,
};
use flowy_error::FlowyResult;
use flowy_folder_pub::cloud::FolderCloudService;
use flowy_sqlite::DBConnection;
use tokio::time;
use tracing::{error, info};

use crate::{
  manager::FolderUser,
  services::sqlite_sql::folder_operation_sql::{
    get_pending_operations_by_workspace_id, update_operation_status, FolderOperation,
  },
};

use super::sync_worker_op_name::{
  CREATE_PAGE_OPERATION_NAME, HTTP_STATUS_COMPLETED, UPDATE_PAGE_OPERATION_NAME,
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
      CREATE_PAGE_OPERATION_NAME => {
        if let Some(payload) = operation.payload {
          let params: CreatePageParams = serde_json::from_str(&payload)?;
          let result = self
            .cloud_service
            .create_page(&operation.workspace_id, params)
            .await;
          // Update operation status to completed
          match result {
            Ok(_) => {
              update_operation_status(conn, operation.id, HTTP_STATUS_COMPLETED.to_string())?;
            },
            Err(e) => {
              error!("Failed to create page: {}", e);
              return Err(e);
            },
          }
        }
      },
      UPDATE_PAGE_OPERATION_NAME => {
        if let Some(page_id) = operation.page_id {
          if let Some(payload) = operation.payload {
            let params: UpdatePageParams = serde_json::from_str(&payload)?;
            let result = self
              .cloud_service
              .update_page(&operation.workspace_id, &page_id, params)
              .await;
            match result {
              Ok(_) => {
                // Only update the operation status to completed if the page is updated successfully
                update_operation_status(conn, operation.id, HTTP_STATUS_COMPLETED.to_string())?;
              },
              Err(e) => {
                error!("Failed to update page: {}", e);
                return Err(e);
              },
            }
          }
        }
      },
      // Add other operation types here
      _ => {
        error!("Unknown operation type: {}", operation.name);
      },
    }

    Ok(())
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
}

// This worker is responsible for syncing the data between the local database and the cloud service.
// All the operations using the http service should call this worker to do the sync work.

use std::sync::Arc;
use std::time::Duration;

use client_api::entity::workspace_dto::{CreatePageParams, FolderView, UpdatePageParams};
use flowy_error::{FlowyError, FlowyResult};
use flowy_folder_pub::cloud::FolderCloudService;
use flowy_sqlite::DBConnection;
use tokio::time;
use tracing::{error, info};

const CREATE_PAGE_OPERATION_NAME: &str = "create_page";
const UPDATE_PAGE_OPERATION_NAME: &str = "update_page";
const MOVE_PAGE_OPERATION_NAME: &str = "move_page";

const HTTP_METHOD_POST: &str = "POST";
const HTTP_METHOD_PUT: &str = "PUT";
const HTTP_METHOD_DELETE: &str = "DELETE";

const HTTP_STATUS_PENDING: &str = "pending";
const HTTP_STATUS_COMPLETED: &str = "completed";

use crate::{
  manager::FolderUser,
  services::sqlite_sql::{
    folder_operation_sql::{
      get_pending_operations_by_workspace_id, update_operation_status, upsert_operation,
      FolderOperation,
    },
    folder_page_sql::{get_page_by_id, upsert_folder_view, upsert_folder_view_with_children},
  },
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

  /// Create a new page and persist it to the local database
  ///
  /// # Workflow
  /// 1. Persist the http service to the local database (operations table)
  /// 2. Call the http service to create a new page
  /// 3. Persist the page to the local database
  /// 4. Send the notification to the client
  pub async fn create_page(&self, workspace_id: &str, params: CreatePageParams) -> FlowyResult<()> {
    let payload = serde_json::to_string(&params).unwrap_or_default();
    let timestamp = chrono::Utc::now().timestamp_millis();

    let operation = FolderOperation::new(
      workspace_id,
      None,
      CREATE_PAGE_OPERATION_NAME,
      HTTP_METHOD_POST,
      HTTP_STATUS_PENDING,
      &payload,
      timestamp,
    );

    let parent_view_id = params.parent_view_id;
    let folder_view = FolderView {
      view_id: parent_view_id.clone(),
      name: params.name.unwrap_or_default(),
      layout: params.layout,
      ..Default::default()
    };

    if let Ok(mut conn) = self.user.sqlite_connection(self.user.user_id()?) {
      upsert_folder_view_with_children(
        &mut conn,
        folder_view,
        workspace_id,
        Some(parent_view_id.clone()),
      )?;
      upsert_operation(&mut conn, operation)?;
    }

    Ok(())
  }

  /// Update a page and persist it to the local database
  ///
  /// # Workflow
  /// 1. Persist the http service to the local database (operations table)
  /// 2. Call the http service to update a page
  /// 3. Persist the page to the local database
  /// 4. Send the notification to the client
  ///
  /// # Parameters
  /// * `conn`: The database connection
  /// * `workspace_id`: The workspace id
  /// * `params`: The update page params
  ///
  /// # Returns
  /// The result of the operation
  pub async fn update_page(
    &self,

    workspace_id: &str,
    page_id: &str,
    params: UpdatePageParams,
  ) -> FlowyResult<()> {
    let payload = serde_json::to_string(&params).unwrap_or_default();
    let timestamp = chrono::Utc::now().timestamp_millis();

    let operation = FolderOperation::new(
      workspace_id,
      Some(page_id),
      UPDATE_PAGE_OPERATION_NAME,
      HTTP_METHOD_PUT,
      HTTP_STATUS_PENDING,
      &payload,
      timestamp,
    );

    if let Ok(mut conn) = self.user.sqlite_connection(self.user.user_id()?) {
      let folder_view = get_page_by_id(&mut conn, workspace_id, page_id, Some(1), false)?;
      let folder_view = self.update_folder_view(folder_view, params);
      let parent_view_id = folder_view.parent_view_id.clone();

      upsert_folder_view(&mut conn, folder_view, workspace_id, Some(parent_view_id))?;
      upsert_operation(&mut conn, operation)?;
    }

    Ok(())
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
        let params: CreatePageParams = serde_json::from_str(&operation.payload)?;
        self
          .cloud_service
          .create_page(&operation.workspace_id, params)
          .await?;
        // Update operation status to completed
        update_operation_status(conn, operation.id, HTTP_STATUS_COMPLETED.to_string())?;
      },
      UPDATE_PAGE_OPERATION_NAME => {
        if let Some(page_id) = operation.page_id {
          let params: UpdatePageParams = serde_json::from_str(&operation.payload)?;
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
      },
      // Add other operation types here
      _ => {
        error!("Unknown operation type: {}", operation.name);
      },
    }

    Ok(())
  }

  fn update_folder_view(
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
}

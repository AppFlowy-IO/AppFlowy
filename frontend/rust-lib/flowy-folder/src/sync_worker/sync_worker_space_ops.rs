use client_api::entity::workspace_dto::{CreateSpaceParams, UpdateSpaceParams};
use flowy_error::{FlowyError, FlowyResult};

use crate::{
  services::sqlite_sql::{
    folder_operation_sql::{upsert_operation, FolderOperation},
    folder_page_sql::{get_page_by_id, upsert_folder_view},
  },
  sync_worker::sync_worker_op_name::MOVE_SPACE_TO_TRASH_OPERATION_NAME,
};

use super::{
  sync_worker::SyncWorker,
  sync_worker_op_name::{
    DELETE_SPACE_OPERATION_NAME, HTTP_METHOD_POST, HTTP_METHOD_PUT, UPDATE_SPACE_OPERATION_NAME,
  },
  sync_worker_page_ops::SyncWorkerPageOps,
};

pub trait SyncWorkerSpaceOps {
  async fn create_space(&self, workspace_id: &str, params: CreateSpaceParams) -> FlowyResult<()>;
  async fn update_space(
    &self,
    workspace_id: &str,
    space_id: &str,
    params: UpdateSpaceParams,
  ) -> FlowyResult<()>;
  async fn move_space_to_trash(&self, workspace_id: &str, space_id: &str) -> FlowyResult<()>;
  async fn restore_space_from_trash(&self, workspace_id: &str, space_id: &str) -> FlowyResult<()>;
  async fn delete_space(&self, workspace_id: &str, space_id: &str) -> FlowyResult<()>;
}

// All the operations are using the similar workflow.
//
// # Workflow
// 1. Persist the http service to the local database (operations table)
// 2. Call the http service to delete a page
// 3. Persist the page to the local database
// 4. Send the notification to the client
impl SyncWorkerSpaceOps for SyncWorker {
  /// Create a new space and persist it to the local database
  ///
  /// # Parameters
  /// * `workspace_id`: The workspace id
  /// * `params`: The create space params
  ///
  /// # Returns
  /// The result of the operation
  async fn create_space(&self, workspace_id: &str, params: CreateSpaceParams) -> FlowyResult<()> {
    // todo: implement the offline support

    self
      .cloud_service
      .create_space(workspace_id, params)
      .await?;

    Ok(())
  }

  /// Update a space and persist it to the local database
  ///
  /// # Parameters
  /// * `workspace_id`: The workspace id
  /// * `space_id`: The space id
  /// * `params`: The update space params
  ///
  /// # Returns
  /// The result of the operation
  async fn update_space(
    &self,
    workspace_id: &str,
    space_id: &str,
    params: UpdateSpaceParams,
  ) -> FlowyResult<()> {
    let payload = serde_json::to_string(&params).unwrap_or_default();

    let operation = FolderOperation::pending(
      workspace_id,
      Some(space_id),
      UPDATE_SPACE_OPERATION_NAME,
      HTTP_METHOD_PUT,
      Some(&payload),
    );

    if let Ok(mut conn) = self.user.sqlite_connection(self.user.user_id()?) {
      let folder_view = get_page_by_id(&mut conn, workspace_id, space_id, Some(1), false)?;
      let folder_view = self.build_update_space_view(folder_view, params);

      upsert_folder_view(
        &mut conn,
        folder_view,
        workspace_id,
        Some(workspace_id.to_string()),
      )?;
      upsert_operation(&mut conn, operation)?;

      return Ok(());
    }

    Err(FlowyError::internal().with_context("Failed to update space"))
  }

  /// Check the move page to trash function for more details
  ///
  /// Note: This function share the same workflow as the move page to trash
  async fn move_space_to_trash(&self, workspace_id: &str, space_id: &str) -> FlowyResult<()> {
    self.move_page_to_trash(workspace_id, space_id).await
  }

  /// Check the restore page from trash function for more details
  ///
  /// Note: This function share the same workflow as the restore page from trash
  async fn restore_space_from_trash(&self, workspace_id: &str, space_id: &str) -> FlowyResult<()> {
    self.restore_page_from_trash(workspace_id, space_id).await
  }

  /// Check the delete page function for more details
  ///
  /// Note: This function share the same workflow as the delete page
  async fn delete_space(&self, workspace_id: &str, space_id: &str) -> FlowyResult<()> {
    self.delete_page(workspace_id, space_id).await
  }
}

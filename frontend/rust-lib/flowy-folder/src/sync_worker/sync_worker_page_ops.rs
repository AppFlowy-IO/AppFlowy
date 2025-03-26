use client_api::entity::workspace_dto::{CreatePageParams, MovePageParams, UpdatePageParams};
use flowy_error::FlowyResult;

use crate::services::sqlite_sql::{
  folder_operation_sql::{upsert_operation, FolderOperation},
  folder_page_sql::{
    delete_folder_view, get_page_by_id, upsert_folder_view, upsert_folder_view_with_children,
  },
};

use super::{
  sync_worker::SyncWorker,
  sync_worker_op_name::{
    CREATE_PAGE_OPERATION_NAME, DELETE_PAGE_OPERATION_NAME, HTTP_METHOD_DELETE, HTTP_METHOD_POST,
    HTTP_METHOD_PUT, HTTP_STATUS_PENDING, MOVE_PAGE_OPERATION_NAME,
    MOVE_PAGE_TO_TRASH_OPERATION_NAME, RESTORE_PAGE_FROM_TRASH_OPERATION_NAME,
    UPDATE_PAGE_OPERATION_NAME,
  },
};

use client_api::entity::workspace_dto::FolderView;

pub trait SyncWorkerPageOps {
  async fn create_page(&self, workspace_id: &str, params: CreatePageParams) -> FlowyResult<()>;
  async fn update_page(
    &self,
    workspace_id: &str,
    page_id: &str,
    params: UpdatePageParams,
  ) -> FlowyResult<()>;
  async fn move_page(
    &self,
    workspace_id: &str,
    page_id: &str,
    params: MovePageParams,
  ) -> FlowyResult<()>;
  async fn move_page_to_trash(&self, workspace_id: &str, page_id: &str) -> FlowyResult<()>;
  async fn restore_page_from_trash(&self, workspace_id: &str, page_id: &str) -> FlowyResult<()>;
  async fn delete_page(&self, workspace_id: &str, page_id: &str) -> FlowyResult<()>;
}

// All the operations are using the similar workflow.
//
// # Workflow
// 1. Persist the http service to the local database (operations table)
// 2. Call the http service to delete a page
// 3. Persist the page to the local database
// 4. Send the notification to the client
impl SyncWorkerPageOps for SyncWorker {
  /// Create a new page and persist it to the local database
  ///
  /// # Parameters
  /// * `workspace_id`: The workspace id
  /// * `params`: The create page params
  ///
  /// # Returns
  /// The result of the operation
  async fn create_page(&self, workspace_id: &str, params: CreatePageParams) -> FlowyResult<()> {
    let payload = serde_json::to_string(&params).unwrap_or_default();
    let timestamp = chrono::Utc::now().timestamp_millis();

    let operation = FolderOperation::new(
      workspace_id,
      None,
      CREATE_PAGE_OPERATION_NAME,
      HTTP_METHOD_POST,
      HTTP_STATUS_PENDING,
      Some(&payload),
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
  /// # Parameters
  /// * `workspace_id`: The workspace id
  /// * `page_id`: The page id
  /// * `params`: The update page params
  ///
  /// # Returns
  /// The result of the operation
  async fn update_page(
    &self,
    workspace_id: &str,
    page_id: &str,
    params: UpdatePageParams,
  ) -> FlowyResult<()> {
    let payload = serde_json::to_string(&params).unwrap_or_default();

    let operation = FolderOperation::pending(
      workspace_id,
      Some(page_id),
      UPDATE_PAGE_OPERATION_NAME,
      HTTP_METHOD_PUT,
      Some(&payload),
    );

    if let Ok(mut conn) = self.user.sqlite_connection(self.user.user_id()?) {
      let folder_view = get_page_by_id(&mut conn, workspace_id, page_id, Some(1), false)?;
      let folder_view = self.build_update_folder_view(folder_view, params);
      let parent_view_id = folder_view.parent_view_id.clone();

      upsert_folder_view(&mut conn, folder_view, workspace_id, Some(parent_view_id))?;
      upsert_operation(&mut conn, operation)?;
    }

    Ok(())
  }

  /// Move a page and persist it to the local database
  ///
  /// # Parameters
  /// * `workspace_id`: The workspace id
  /// * `page_id`: The page id
  /// * `params`: The move page params
  ///
  /// # Returns
  /// The result of the operation
  async fn move_page(
    &self,
    workspace_id: &str,
    page_id: &str,
    params: MovePageParams,
  ) -> FlowyResult<()> {
    let payload = serde_json::to_string(&params).unwrap_or_default();

    let operation = FolderOperation::pending(
      workspace_id,
      Some(page_id),
      MOVE_PAGE_OPERATION_NAME,
      HTTP_METHOD_POST,
      Some(&payload),
    );

    if let Ok(mut conn) = self.user.sqlite_connection(self.user.user_id()?) {
      let folder_view = get_page_by_id(&mut conn, workspace_id, page_id, Some(1), false)?;
      let folder_view = self.build_moved_folder_view(folder_view, params);
      let parent_view_id = folder_view.parent_view_id.clone();

      upsert_folder_view(&mut conn, folder_view, workspace_id, Some(parent_view_id))?;
      upsert_operation(&mut conn, operation)?;
    }

    Ok(())
  }

  /// Move the page to the trash and persist it to the local database
  ///
  /// # Parameters
  /// * `workspace_id`: The workspace id
  /// * `page_id`: The page id
  ///
  /// # Returns
  /// The result of the operation
  async fn move_page_to_trash(&self, workspace_id: &str, page_id: &str) -> FlowyResult<()> {
    let operation = FolderOperation::pending(
      workspace_id,
      Some(page_id),
      MOVE_PAGE_TO_TRASH_OPERATION_NAME,
      HTTP_METHOD_POST,
      None,
    );

    if let Ok(mut conn) = self.user.sqlite_connection(self.user.user_id()?) {
      // todo: create a trash table
      upsert_operation(&mut conn, operation)?;
    }

    Ok(())
  }

  /// Restore a page from the trash and persist it to the local database
  ///
  /// # Parameters
  /// * `workspace_id`: The workspace id
  /// * `page_id`: The page id
  ///
  /// # Returns
  /// The result of the operation
  async fn restore_page_from_trash(&self, workspace_id: &str, page_id: &str) -> FlowyResult<()> {
    let operation = FolderOperation::pending(
      workspace_id,
      Some(page_id),
      RESTORE_PAGE_FROM_TRASH_OPERATION_NAME,
      HTTP_METHOD_POST,
      None,
    );

    if let Ok(mut conn) = self.user.sqlite_connection(self.user.user_id()?) {
      // todo: create a trash table
      upsert_operation(&mut conn, operation)?;
    }

    Ok(())
  }

  /// Delete a page and persist it to the local database
  async fn delete_page(&self, workspace_id: &str, page_id: &str) -> FlowyResult<()> {
    let operation = FolderOperation::pending(
      workspace_id,
      Some(page_id),
      DELETE_PAGE_OPERATION_NAME,
      HTTP_METHOD_DELETE,
      None,
    );

    if let Ok(mut conn) = self.user.sqlite_connection(self.user.user_id()?) {
      delete_folder_view(&mut conn, workspace_id, page_id)?;
      upsert_operation(&mut conn, operation)?;
    }

    Ok(())
  }
}

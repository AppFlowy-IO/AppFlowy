use client_api::entity::workspace_dto::{CreatePageParams, UpdatePageParams};
use flowy_error::FlowyResult;

use crate::services::sqlite_sql::{
  folder_operation_sql::{upsert_operation, FolderOperation},
  folder_page_sql::{get_page_by_id, upsert_folder_view, upsert_folder_view_with_children},
};

use super::{
  sync_worker::SyncWorker,
  sync_worker_op_name::{
    CREATE_PAGE_OPERATION_NAME, HTTP_METHOD_POST, HTTP_METHOD_PUT, HTTP_STATUS_PENDING,
    UPDATE_PAGE_OPERATION_NAME,
  },
};

use client_api::entity::workspace_dto::FolderView;

pub trait SyncWorkerPageOps {
  async fn create_page(&self, workspace_id: &str, params: CreatePageParams) -> FlowyResult<()>;
  async fn update_page(
    &self,
    workspace_id: &str,
    view_id: &str,
    params: UpdatePageParams,
  ) -> FlowyResult<()>;
}

impl SyncWorkerPageOps for SyncWorker {
  /// Create a new page and persist it to the local database
  ///
  /// # Workflow
  /// 1. Persist the http service to the local database (operations table)
  /// 2. Call the http service to create a new page
  /// 3. Persist the page to the local database
  /// 4. Send the notification to the client
  async fn create_page(&self, workspace_id: &str, params: CreatePageParams) -> FlowyResult<()> {
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
  async fn update_page(
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
}

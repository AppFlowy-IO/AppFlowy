use crate::entities::UserFolderPB;
use flowy_error::{ErrorCode, FlowyError};

pub(crate) fn folder_not_init_error() -> FlowyError {
  FlowyError::internal().with_context("Folder not initialized")
}

pub(crate) fn workspace_data_not_sync_error(uid: i64, workspace_id: &str) -> FlowyError {
  FlowyError::from(ErrorCode::WorkspaceDataNotSync).with_payload(UserFolderPB {
    uid,
    workspace_id: workspace_id.to_string(),
  })
}

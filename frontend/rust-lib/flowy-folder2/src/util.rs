use std::sync::Arc;

use collab_integrate::YrsDocAction;
use flowy_error::{ErrorCode, FlowyError, FlowyResult};

use crate::entities::UserFolderPB;
use crate::manager::FolderUser;

pub(crate) fn folder_not_init_error() -> FlowyError {
  FlowyError::internal().with_context("Folder not initialized")
}

pub(crate) fn is_exist_in_local_disk(
  user: &Arc<dyn FolderUser>,
  doc_id: &str,
) -> FlowyResult<bool> {
  let uid = user.user_id()?;
  if let Some(collab_db) = user.collab_db(uid)?.upgrade() {
    let read_txn = collab_db.read_txn();
    Ok(read_txn.is_exist(uid, doc_id))
  } else {
    Ok(false)
  }
}

pub(crate) fn workspace_data_not_sync_error(uid: i64, workspace_id: &str) -> FlowyError {
  FlowyError::from(ErrorCode::WorkspaceDataNotSync).with_payload(UserFolderPB {
    uid,
    workspace_id: workspace_id.to_string(),
  })
}

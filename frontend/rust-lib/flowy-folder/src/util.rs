use collab_folder::Folder;
use std::sync::Arc;
use tracing::{event, instrument};

use collab_integrate::CollabKVAction;
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_folder_pub::folder_builder::ParentChildViews;

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

#[instrument(level = "debug", skip(folder, view))]
pub(crate) fn insert_parent_child_views(folder: &Folder, view: ParentChildViews) {
  event!(
    tracing::Level::DEBUG,
    "Inserting view: {}, view children: {}",
    view.parent_view.id,
    view.child_views.len()
  );
  folder.insert_view(view.parent_view, None);
  for child_view in view.child_views {
    insert_parent_child_views(folder, child_view);
  }
}

use crate::entities::UserFolderPB;
use collab_folder::hierarchy_builder::ParentChildViews;
use collab_folder::Folder;
use flowy_error::{ErrorCode, FlowyError};
use tracing::{event, instrument};

pub(crate) fn folder_not_init_error() -> FlowyError {
  FlowyError::internal().with_context("Folder not initialized")
}

pub(crate) fn workspace_data_not_sync_error(uid: i64, workspace_id: &str) -> FlowyError {
  FlowyError::from(ErrorCode::WorkspaceDataNotSync).with_payload(UserFolderPB {
    uid,
    workspace_id: workspace_id.to_string(),
  })
}

#[instrument(level = "debug", skip(folder, view))]
pub(crate) fn insert_parent_child_views(folder: &mut Folder, view: ParentChildViews) {
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

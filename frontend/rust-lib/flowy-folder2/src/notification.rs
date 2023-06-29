use std::sync::Arc;

use collab_folder::core::{View, Workspace};

use flowy_derive::ProtoBuf_Enum;
use flowy_notification::NotificationBuilder;
use lib_dispatch::prelude::ToBytes;

use crate::entities::{view_pb_without_child_views, WorkspacePB, WorkspaceSettingPB};

const OBSERVABLE_CATEGORY: &str = "Workspace";

#[derive(ProtoBuf_Enum, Debug, Default)]
pub(crate) enum FolderNotification {
  #[default]
  Unknown = 0,
  /// Trigger after creating a workspace
  DidCreateWorkspace = 1,
  // /// Trigger after updating a workspace
  DidUpdateWorkspace = 2,

  DidUpdateWorkspaceViews = 3,
  /// Trigger when the settings of the workspace are changed. The changes including the latest visiting view, etc
  DidUpdateWorkspaceSetting = 4,
  DidUpdateView = 29,
  DidUpdateChildViews = 30,
  /// Trigger after deleting the view
  DidDeleteView = 31,
  /// Trigger when restore the view from trash
  DidRestoreView = 32,
  /// Trigger after moving the view to trash
  DidMoveViewToTrash = 33,
  /// Trigger when the number of trash is changed
  DidUpdateTrash = 34,
}

impl std::convert::From<FolderNotification> for i32 {
  fn from(notification: FolderNotification) -> Self {
    notification as i32
  }
}

#[tracing::instrument(level = "trace")]
pub(crate) fn send_notification(id: &str, ty: FolderNotification) -> NotificationBuilder {
  NotificationBuilder::new(id, ty, OBSERVABLE_CATEGORY)
}

/// The [CURRENT_WORKSPACE] represents as the current workspace that opened by the
/// user. Only one workspace can be opened at a time.
const CURRENT_WORKSPACE: &str = "current-workspace";
pub(crate) fn send_workspace_notification<T: ToBytes>(ty: FolderNotification, payload: T) {
  send_notification(CURRENT_WORKSPACE, ty)
    .payload(payload)
    .send();
}

pub(crate) fn send_workspace_setting_notification(
  current_workspace: Option<Workspace>,
  current_view: Option<Arc<View>>,
) -> Option<()> {
  let workspace: WorkspacePB = current_workspace?.into();
  let latest_view = current_view.map(view_pb_without_child_views);
  let setting = WorkspaceSettingPB {
    workspace,
    latest_view,
  };
  send_workspace_notification(FolderNotification::DidUpdateWorkspaceSetting, setting);
  None
}

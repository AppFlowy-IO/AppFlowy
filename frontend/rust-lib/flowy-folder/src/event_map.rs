use std::sync::Weak;

use strum_macros::Display;

use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use lib_dispatch::prelude::*;

use crate::event_handler::*;
use crate::manager::FolderManager;

pub fn init(folder: Weak<FolderManager>) -> AFPlugin {
  AFPlugin::new().name("Flowy-Folder").state(folder)
    // Workspace
    .event(FolderEvent::CreateFolderWorkspace, create_workspace_handler)
    .event(FolderEvent::GetCurrentWorkspaceSetting, read_current_workspace_setting_handler)
    .event(FolderEvent::ReadCurrentWorkspace, read_current_workspace_handler)
    .event(FolderEvent::ReadWorkspaceViews, get_workspace_views_handler)
    .event(FolderEvent::CreateView, create_view_handler)
    .event(FolderEvent::CreateOrphanView, create_orphan_view_handler)
    .event(FolderEvent::GetView, get_view_handler)
    .event(FolderEvent::GetAllViews, get_all_views_handler)
    .event(FolderEvent::UpdateView, update_view_handler)
    .event(FolderEvent::DeleteView, delete_view_handler)
    .event(FolderEvent::DuplicateView, duplicate_view_handler)
    .event(FolderEvent::SetLatestView, set_latest_view_handler)
    .event(FolderEvent::CloseView, close_view_handler)
    .event(FolderEvent::MoveView, move_view_handler)
    .event(FolderEvent::MoveNestedView, move_nested_view_handler)
    .event(FolderEvent::ListTrashItems, read_trash_handler)
    .event(FolderEvent::RestoreTrashItem, putback_trash_handler)
    .event(FolderEvent::PermanentlyDeleteTrashItem, delete_trash_handler)
    .event(FolderEvent::RecoverAllTrashItems, restore_all_trash_handler)
    .event(FolderEvent::PermanentlyDeleteAllTrashItem, delete_my_trash_handler)
    .event(FolderEvent::ImportData, import_data_handler)
    .event(FolderEvent::ImportZipFile, import_zip_file_handler)
    .event(FolderEvent::GetFolderSnapshots, get_folder_snapshots_handler)
    .event(FolderEvent::UpdateViewIcon, update_view_icon_handler)
    .event(FolderEvent::ReadFavorites, read_favorites_handler)
    .event(FolderEvent::ReadRecentViews, read_recent_views_handler)
    .event(FolderEvent::ToggleFavorite, toggle_favorites_handler)
    .event(FolderEvent::UpdateRecentViews, update_recent_views_handler)
    .event(FolderEvent::ReadPrivateViews, read_private_views_handler)
    .event(FolderEvent::ReadCurrentWorkspaceViews, get_current_workspace_views_handler)
    .event(FolderEvent::UpdateViewVisibilityStatus, update_view_visibility_status_handler)
    .event(FolderEvent::GetViewAncestors, get_view_ancestors_handler)
    .event(FolderEvent::PublishView, publish_view_handler)
    .event(FolderEvent::GetPublishInfo, get_publish_info_handler)
    .event(FolderEvent::UnpublishViews, unpublish_views_handler)
    .event(FolderEvent::SetPublishNamespace, set_publish_namespace_handler)
    .event(FolderEvent::GetPublishNamespace, get_publish_namespace_handler)
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "FlowyError"]
pub enum FolderEvent {
  /// Create a new workspace
  #[event(input = "CreateWorkspacePayloadPB", output = "WorkspacePB")]
  CreateFolderWorkspace = 0,

  /// Read the current opening workspace. Currently, we only support one workspace
  #[event(output = "WorkspaceSettingPB")]
  GetCurrentWorkspaceSetting = 1,

  /// Return a list of workspaces that the current user can access.
  #[event(output = "WorkspacePB")]
  ReadCurrentWorkspace = 2,

  /// Delete the workspace
  #[event(input = "WorkspaceIdPB")]
  DeleteWorkspace = 3,

  /// Return a list of views of the specified workspace.
  /// Only the first level of child views are included.
  #[event(input = "GetWorkspaceViewPB", output = "RepeatedViewPB")]
  ReadWorkspaceViews = 5,

  /// Create a new view in the corresponding app
  #[event(input = "CreateViewPayloadPB", output = "ViewPB")]
  CreateView = 10,

  /// Return the view info
  #[event(input = "ViewIdPB", output = "ViewPB")]
  GetView = 11,

  /// Update the view's properties including the name,description, etc.
  #[event(input = "UpdateViewPayloadPB", output = "ViewPB")]
  UpdateView = 12,

  /// Move the view to the trash folder
  #[event(input = "RepeatedViewIdPB")]
  DeleteView = 13,

  /// Duplicate the view
  #[event(input = "DuplicateViewPayloadPB", output = "ViewPB")]
  DuplicateView = 14,

  /// Close and release the resources that are used by this view.
  /// It should get called when the 'View' page get destroy
  #[event(input = "ViewIdPB")]
  CloseView = 15,

  /// Create a new view in the corresponding app
  #[event(input = "CreateOrphanViewPayloadPB", output = "ViewPB")]
  CreateOrphanView = 16,

  /// Return the view info
  #[event(output = "RepeatedViewPB")]
  GetAllViews = 17,

  #[event()]
  CopyLink = 20,

  /// Set the current visiting view
  #[event(input = "ViewIdPB")]
  SetLatestView = 21,

  /// Move the view or app to another place
  #[event(input = "MoveViewPayloadPB")]
  MoveView = 22,

  /// Read the trash that was deleted by the user
  #[event(output = "RepeatedTrashPB")]
  ListTrashItems = 23,

  /// Put back the trash to the origin folder
  #[event(input = "TrashIdPB")]
  RestoreTrashItem = 24,

  /// Delete the trash from the disk
  #[event(input = "RepeatedTrashIdPB")]
  PermanentlyDeleteTrashItem = 25,

  /// Put back all the trash to its original folder
  #[event()]
  RecoverAllTrashItems = 26,

  /// Delete all the trash from the disk
  #[event()]
  PermanentlyDeleteAllTrashItem = 27,

  #[event(input = "ImportPayloadPB", output = "RepeatedViewPB")]
  ImportData = 30,

  #[event(input = "WorkspaceIdPB", output = "RepeatedFolderSnapshotPB")]
  GetFolderSnapshots = 31,
  /// Moves a nested view to a new location in the hierarchy.
  ///
  /// This function takes the `view_id` of the view to be moved,
  /// `new_parent_id` of the view under which the `view_id` should be moved,
  /// and an optional `prev_view_id` to position the `view_id` right after
  /// this specific view.
  #[event(input = "MoveNestedViewPayloadPB")]
  MoveNestedView = 32,

  #[event(output = "RepeatedFavoriteViewPB")]
  ReadFavorites = 33,

  #[event(input = "RepeatedViewIdPB")]
  ToggleFavorite = 34,

  #[event(input = "UpdateViewIconPayloadPB")]
  UpdateViewIcon = 35,

  #[event(input = "ReadRecentViewsPB", output = "RepeatedRecentViewPB")]
  ReadRecentViews = 36,

  // used for add or remove recent views, like history
  #[event(input = "UpdateRecentViewPayloadPB")]
  UpdateRecentViews = 37,

  #[event(input = "GetWorkspaceViewPB", output = "RepeatedViewPB")]
  ReadPrivateViews = 39,

  /// Return a list of views of the current workspace.
  /// Only the first level of child views are included.
  #[event(output = "RepeatedViewPB")]
  ReadCurrentWorkspaceViews = 40,

  #[event(input = "UpdateViewVisibilityStatusPayloadPB")]
  UpdateViewVisibilityStatus = 41,

  /// Return the ancestors of the view
  #[event(input = "ViewIdPB", output = "RepeatedViewPB")]
  GetViewAncestors = 42,

  #[event(input = "PublishViewParamsPB")]
  PublishView = 43,

  #[event(input = "ViewIdPB", output = "PublishInfoResponsePB")]
  GetPublishInfo = 44,

  #[event(output = "PublishNamespacePB")]
  GetPublishNamespace = 45,

  #[event(input = "SetPublishNamespacePayloadPB")]
  SetPublishNamespace = 46,

  #[event(input = "UnpublishViewsPayloadPB")]
  UnpublishViews = 47,

  #[event(input = "ImportZipPB")]
  ImportZipFile = 48,
}

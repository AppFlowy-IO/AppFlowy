use crate::event_handler::*;
use crate::manager::Folder2Manager;
use flowy_derive::{Flowy_Event, ProtoBuf_Enum};

use lib_dispatch::prelude::*;
use std::sync::Arc;
use strum_macros::Display;

pub fn init(folder: Arc<Folder2Manager>) -> AFPlugin {
  AFPlugin::new().name("Flowy-Folder").state(folder)
    // Workspace
    .event(FolderEvent::CreateWorkspace, create_workspace_handler)
    .event(
        FolderEvent::ReadCurrentWorkspace,
        read_cur_workspace_setting_handler,
    )
    .event(FolderEvent::ReadWorkspaces, read_workspaces_handler)
    .event(FolderEvent::OpenWorkspace, open_workspace_handler)
    .event(FolderEvent::ReadWorkspaceApps, read_workspace_apps_handler)
     // View
    .event(FolderEvent::CreateView, create_view_handler)
    .event(FolderEvent::ReadView, read_view_handler)
    .event(FolderEvent::UpdateView, update_view_handler)
    .event(FolderEvent::DeleteView, delete_view_handler)
    .event(FolderEvent::DuplicateView, duplicate_view_handler)
    .event(FolderEvent::SetLatestView, set_latest_view_handler)
    .event(FolderEvent::CloseView, close_view_handler)
    .event(FolderEvent::MoveItem, move_item_handler)
    // Trash
    .event(FolderEvent::ReadTrash, read_trash_handler)
    .event(FolderEvent::PutbackTrash, putback_trash_handler)
    .event(FolderEvent::DeleteTrash, delete_trash_handler)
    .event(FolderEvent::RestoreAllTrash, restore_all_trash_handler)
    .event(FolderEvent::DeleteAllTrash, delete_all_trash_handler)
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "FlowyError"]
pub enum FolderEvent {
  /// Create a new workspace
  #[event(input = "CreateWorkspacePayloadPB", output = "WorkspacePB")]
  CreateWorkspace = 0,

  /// Read the current opening workspace
  #[event(output = "WorkspaceSettingPB")]
  ReadCurrentWorkspace = 1,

  /// Open the workspace and mark it as the current workspace
  #[event(input = "WorkspaceIdPB", output = "RepeatedWorkspacePB")]
  ReadWorkspaces = 2,

  /// Delete the workspace
  #[event(input = "WorkspaceIdPB")]
  DeleteWorkspace = 3,

  /// Open the workspace and mark it as the current workspace
  #[event(input = "WorkspaceIdPB", output = "WorkspacePB")]
  OpenWorkspace = 4,

  /// Return a list of apps that belong to this workspace
  #[event(input = "WorkspaceIdPB", output = "RepeatedAppPB")]
  ReadWorkspaceApps = 5,

  /// Create a new app
  #[event(input = "CreateAppPayloadPB", output = "AppPB")]
  CreateApp = 101,

  /// Delete the app
  #[event(input = "AppIdPB")]
  DeleteApp = 102,

  /// Read the app
  #[event(input = "AppIdPB", output = "AppPB")]
  ReadApp = 103,

  /// Update the app's properties including the name,description, etc.
  #[event(input = "UpdateAppPayloadPB")]
  UpdateApp = 104,

  /// Create a new view in the corresponding app
  #[event(input = "CreateViewPayloadPB", output = "ViewPB")]
  CreateView = 201,

  /// Return the view info
  #[event(input = "ViewIdPB", output = "ViewPB")]
  ReadView = 202,

  /// Update the view's properties including the name,description, etc.
  #[event(input = "UpdateViewPayloadPB", output = "ViewPB")]
  UpdateView = 203,

  /// Move the view to the trash folder
  #[event(input = "RepeatedViewIdPB")]
  DeleteView = 204,

  /// Duplicate the view
  #[event(input = "ViewPB")]
  DuplicateView = 205,

  /// Close and release the resources that are used by this view.
  /// It should get called when the 'View' page get destroy
  #[event(input = "ViewIdPB")]
  CloseView = 206,

  #[event()]
  CopyLink = 220,

  /// Set the current visiting view
  #[event(input = "ViewIdPB")]
  SetLatestView = 221,

  /// Move the view or app to another place
  #[event(input = "MoveFolderItemPayloadPB")]
  MoveItem = 230,

  /// Read the trash that was deleted by the user
  #[event(output = "RepeatedTrashPB")]
  ReadTrash = 300,

  /// Put back the trash to the origin folder
  #[event(input = "TrashIdPB")]
  PutbackTrash = 301,

  /// Delete the trash from the disk
  #[event(input = "RepeatedTrashIdPB")]
  DeleteTrash = 302,

  /// Put back all the trash to its original folder
  #[event()]
  RestoreAllTrash = 303,

  /// Delete all the trash from the disk
  #[event()]
  DeleteAllTrash = 304,
}

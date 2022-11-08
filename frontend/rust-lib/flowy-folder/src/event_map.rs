use crate::{
    entities::{
        app::{AppIdPB, CreateAppParams, UpdateAppParams},
        trash::RepeatedTrashIdPB,
        view::{CreateViewParams, RepeatedViewIdPB, UpdateViewParams, ViewIdPB},
        workspace::{CreateWorkspaceParams, UpdateWorkspaceParams, WorkspaceIdPB},
    },
    errors::FlowyError,
    manager::FolderManager,
    services::{app::event_handler::*, trash::event_handler::*, view::event_handler::*, workspace::event_handler::*},
};
use flowy_database::{ConnectionPool, DBConnection};
use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use folder_rev_model::{AppRevision, TrashRevision, ViewRevision, WorkspaceRevision};
use lib_dispatch::prelude::*;
use lib_infra::future::FutureResult;
use std::sync::Arc;
use strum_macros::Display;

pub trait WorkspaceDeps: WorkspaceUser + WorkspaceDatabase {}

pub trait WorkspaceUser: Send + Sync {
    fn user_id(&self) -> Result<String, FlowyError>;
    fn token(&self) -> Result<String, FlowyError>;
}

pub trait WorkspaceDatabase: Send + Sync {
    fn db_pool(&self) -> Result<Arc<ConnectionPool>, FlowyError>;

    fn db_connection(&self) -> Result<DBConnection, FlowyError> {
        let pool = self.db_pool()?;
        let conn = pool.get().map_err(|e| FlowyError::internal().context(e))?;
        Ok(conn)
    }
}

pub fn create(folder: Arc<FolderManager>) -> Module {
    let mut module = Module::new()
        .name("Flowy-Workspace")
        .data(folder.workspace_controller.clone())
        .data(folder.app_controller.clone())
        .data(folder.view_controller.clone())
        .data(folder.trash_controller.clone())
        .data(folder.clone());

    // Workspace
    module = module
        .event(FolderEvent::CreateWorkspace, create_workspace_handler)
        .event(FolderEvent::ReadCurrentWorkspace, read_cur_workspace_handler)
        .event(FolderEvent::ReadWorkspaces, read_workspaces_handler)
        .event(FolderEvent::OpenWorkspace, open_workspace_handler)
        .event(FolderEvent::ReadWorkspaceApps, read_workspace_apps_handler);

    // App
    module = module
        .event(FolderEvent::CreateApp, create_app_handler)
        .event(FolderEvent::ReadApp, read_app_handler)
        .event(FolderEvent::UpdateApp, update_app_handler)
        .event(FolderEvent::DeleteApp, delete_app_handler);

    // View
    module = module
        .event(FolderEvent::CreateView, create_view_handler)
        .event(FolderEvent::ReadView, read_view_handler)
        .event(FolderEvent::UpdateView, update_view_handler)
        .event(FolderEvent::ReadViewInfo, read_view_info_handler)
        .event(FolderEvent::DeleteView, delete_view_handler)
        .event(FolderEvent::DuplicateView, duplicate_view_handler)
        .event(FolderEvent::SetLatestView, set_latest_view_handler)
        .event(FolderEvent::CloseView, close_view_handler)
        .event(FolderEvent::MoveFolderItem, move_item_handler);

    // Trash
    module = module
        .event(FolderEvent::ReadTrash, read_trash_handler)
        .event(FolderEvent::PutbackTrash, putback_trash_handler)
        .event(FolderEvent::DeleteTrash, delete_trash_handler)
        .event(FolderEvent::RestoreAllTrash, restore_all_trash_handler)
        .event(FolderEvent::DeleteAllTrash, delete_all_trash_handler);

    module
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "FlowyError"]
pub enum FolderEvent {
    #[event(input = "CreateWorkspacePayloadPB", output = "WorkspacePB")]
    CreateWorkspace = 0,

    #[event(output = "WorkspaceSettingPB")]
    ReadCurrentWorkspace = 1,

    #[event(input = "WorkspaceIdPB", output = "RepeatedWorkspacePB")]
    ReadWorkspaces = 2,

    #[event(input = "WorkspaceIdPB")]
    DeleteWorkspace = 3,

    #[event(input = "WorkspaceIdPB", output = "WorkspacePB")]
    OpenWorkspace = 4,

    #[event(input = "WorkspaceIdPB", output = "RepeatedAppPB")]
    ReadWorkspaceApps = 5,

    #[event(input = "CreateAppPayloadPB", output = "AppPB")]
    CreateApp = 101,

    #[event(input = "AppIdPB")]
    DeleteApp = 102,

    #[event(input = "AppIdPB", output = "AppPB")]
    ReadApp = 103,

    #[event(input = "UpdateAppPayloadPB")]
    UpdateApp = 104,

    #[event(input = "CreateViewPayloadPB", output = "ViewPB")]
    CreateView = 201,

    #[event(input = "ViewIdPB", output = "ViewPB")]
    ReadView = 202,

    #[event(input = "UpdateViewPayloadPB", output = "ViewPB")]
    UpdateView = 203,

    #[event(input = "RepeatedViewIdPB")]
    DeleteView = 204,

    #[event(input = "ViewPB")]
    DuplicateView = 205,

    #[event(input = "ViewIdPB")]
    CloseView = 206,

    #[event(input = "ViewIdPB", output = "ViewInfoPB")]
    ReadViewInfo = 207,

    #[event()]
    CopyLink = 220,

    #[event(input = "ViewIdPB")]
    SetLatestView = 221,

    #[event(input = "MoveFolderItemPayloadPB")]
    MoveFolderItem = 230,

    #[event(output = "RepeatedTrashPB")]
    ReadTrash = 300,

    #[event(input = "TrashIdPB")]
    PutbackTrash = 301,

    #[event(input = "RepeatedTrashIdPB")]
    DeleteTrash = 302,

    #[event()]
    RestoreAllTrash = 303,

    #[event()]
    DeleteAllTrash = 304,
}

pub trait FolderCouldServiceV1: Send + Sync {
    fn init(&self);

    // Workspace
    fn create_workspace(
        &self,
        token: &str,
        params: CreateWorkspaceParams,
    ) -> FutureResult<WorkspaceRevision, FlowyError>;

    fn read_workspace(&self, token: &str, params: WorkspaceIdPB) -> FutureResult<Vec<WorkspaceRevision>, FlowyError>;

    fn update_workspace(&self, token: &str, params: UpdateWorkspaceParams) -> FutureResult<(), FlowyError>;

    fn delete_workspace(&self, token: &str, params: WorkspaceIdPB) -> FutureResult<(), FlowyError>;

    // View
    fn create_view(&self, token: &str, params: CreateViewParams) -> FutureResult<ViewRevision, FlowyError>;

    fn read_view(&self, token: &str, params: ViewIdPB) -> FutureResult<Option<ViewRevision>, FlowyError>;

    fn delete_view(&self, token: &str, params: RepeatedViewIdPB) -> FutureResult<(), FlowyError>;

    fn update_view(&self, token: &str, params: UpdateViewParams) -> FutureResult<(), FlowyError>;

    // App
    fn create_app(&self, token: &str, params: CreateAppParams) -> FutureResult<AppRevision, FlowyError>;

    fn read_app(&self, token: &str, params: AppIdPB) -> FutureResult<Option<AppRevision>, FlowyError>;

    fn update_app(&self, token: &str, params: UpdateAppParams) -> FutureResult<(), FlowyError>;

    fn delete_app(&self, token: &str, params: AppIdPB) -> FutureResult<(), FlowyError>;

    // Trash
    fn create_trash(&self, token: &str, params: RepeatedTrashIdPB) -> FutureResult<(), FlowyError>;

    fn delete_trash(&self, token: &str, params: RepeatedTrashIdPB) -> FutureResult<(), FlowyError>;

    fn read_trash(&self, token: &str) -> FutureResult<Vec<TrashRevision>, FlowyError>;
}

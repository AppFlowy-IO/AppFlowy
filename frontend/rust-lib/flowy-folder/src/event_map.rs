use crate::{
    controller::FolderManager,
    entities::{
        app::{App, AppId, CreateAppParams, UpdateAppParams},
        trash::{RepeatedTrash, RepeatedTrashId},
        view::{CreateViewParams, RepeatedViewId, UpdateViewParams, View, ViewId},
        workspace::{CreateWorkspaceParams, RepeatedWorkspace, UpdateWorkspaceParams, Workspace, WorkspaceId},
    },
    errors::FlowyError,
    services::{app::event_handler::*, trash::event_handler::*, view::event_handler::*, workspace::event_handler::*},
};
use flowy_database::DBConnection;
use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use strum_macros::Display;

use lib_dispatch::prelude::*;
use lib_infra::future::FutureResult;
use lib_sqlite::ConnectionPool;
use std::sync::Arc;

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

    module = module
        .event(FolderEvent::CreateWorkspace, create_workspace_handler)
        .event(FolderEvent::ReadCurWorkspace, read_cur_workspace_handler)
        .event(FolderEvent::ReadWorkspaces, read_workspaces_handler)
        .event(FolderEvent::OpenWorkspace, open_workspace_handler)
        .event(FolderEvent::ReadWorkspaceApps, read_workspace_apps_handler);

    module = module
        .event(FolderEvent::CreateApp, create_app_handler)
        .event(FolderEvent::ReadApp, read_app_handler)
        .event(FolderEvent::UpdateApp, update_app_handler)
        .event(FolderEvent::DeleteApp, delete_app_handler);

    module = module
        .event(FolderEvent::CreateView, create_view_handler)
        .event(FolderEvent::ReadView, read_view_handler)
        .event(FolderEvent::UpdateView, update_view_handler)
        .event(FolderEvent::DeleteView, delete_view_handler)
        .event(FolderEvent::DuplicateView, duplicate_view_handler)
        .event(FolderEvent::OpenView, open_document_handler)
        .event(FolderEvent::CloseView, close_view_handler)
        .event(FolderEvent::ApplyDocDelta, document_delta_handler);

    module = module
        .event(FolderEvent::ReadTrash, read_trash_handler)
        .event(FolderEvent::PutbackTrash, putback_trash_handler)
        .event(FolderEvent::DeleteTrash, delete_trash_handler)
        .event(FolderEvent::RestoreAllTrash, restore_all_trash_handler)
        .event(FolderEvent::DeleteAllTrash, delete_all_trash_handler);

    module = module.event(FolderEvent::ExportDocument, export_handler);

    module
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "FlowyError"]
pub enum FolderEvent {
    #[event(input = "CreateWorkspaceRequest", output = "Workspace")]
    CreateWorkspace = 0,

    #[event(output = "CurrentWorkspaceSetting")]
    ReadCurWorkspace = 1,

    #[event(input = "QueryWorkspaceRequest", output = "RepeatedWorkspace")]
    ReadWorkspaces = 2,

    #[event(input = "QueryWorkspaceRequest")]
    DeleteWorkspace = 3,

    #[event(input = "QueryWorkspaceRequest", output = "Workspace")]
    OpenWorkspace = 4,

    #[event(input = "QueryWorkspaceRequest", output = "RepeatedApp")]
    ReadWorkspaceApps = 5,

    #[event(input = "CreateAppRequest", output = "App")]
    CreateApp = 101,

    #[event(input = "QueryAppRequest")]
    DeleteApp = 102,

    #[event(input = "QueryAppRequest", output = "App")]
    ReadApp = 103,

    #[event(input = "UpdateAppRequest")]
    UpdateApp = 104,

    #[event(input = "CreateViewRequest", output = "View")]
    CreateView = 201,

    #[event(input = "ViewId", output = "View")]
    ReadView = 202,

    #[event(input = "UpdateViewRequest", output = "View")]
    UpdateView = 203,

    #[event(input = "RepeatedViewId")]
    DeleteView = 204,

    #[event(input = "ViewId")]
    DuplicateView = 205,

    #[event()]
    CopyLink = 206,

    #[event(input = "ViewId", output = "DocumentDelta")]
    OpenView = 207,

    #[event(input = "ViewId")]
    CloseView = 208,

    #[event(output = "RepeatedTrash")]
    ReadTrash = 300,

    #[event(input = "TrashId")]
    PutbackTrash = 301,

    #[event(input = "RepeatedTrashId")]
    DeleteTrash = 302,

    #[event()]
    RestoreAllTrash = 303,

    #[event()]
    DeleteAllTrash = 304,

    #[event(input = "DocumentDelta", output = "DocumentDelta")]
    ApplyDocDelta = 400,

    #[event(input = "ExportRequest", output = "ExportData")]
    ExportDocument = 500,
}

pub trait FolderCouldServiceV1: Send + Sync {
    fn init(&self);

    // Workspace
    fn create_workspace(&self, token: &str, params: CreateWorkspaceParams) -> FutureResult<Workspace, FlowyError>;

    fn read_workspace(&self, token: &str, params: WorkspaceId) -> FutureResult<RepeatedWorkspace, FlowyError>;

    fn update_workspace(&self, token: &str, params: UpdateWorkspaceParams) -> FutureResult<(), FlowyError>;

    fn delete_workspace(&self, token: &str, params: WorkspaceId) -> FutureResult<(), FlowyError>;

    // View
    fn create_view(&self, token: &str, params: CreateViewParams) -> FutureResult<View, FlowyError>;

    fn read_view(&self, token: &str, params: ViewId) -> FutureResult<Option<View>, FlowyError>;

    fn delete_view(&self, token: &str, params: RepeatedViewId) -> FutureResult<(), FlowyError>;

    fn update_view(&self, token: &str, params: UpdateViewParams) -> FutureResult<(), FlowyError>;

    // App
    fn create_app(&self, token: &str, params: CreateAppParams) -> FutureResult<App, FlowyError>;

    fn read_app(&self, token: &str, params: AppId) -> FutureResult<Option<App>, FlowyError>;

    fn update_app(&self, token: &str, params: UpdateAppParams) -> FutureResult<(), FlowyError>;

    fn delete_app(&self, token: &str, params: AppId) -> FutureResult<(), FlowyError>;

    // Trash
    fn create_trash(&self, token: &str, params: RepeatedTrashId) -> FutureResult<(), FlowyError>;

    fn delete_trash(&self, token: &str, params: RepeatedTrashId) -> FutureResult<(), FlowyError>;

    fn read_trash(&self, token: &str) -> FutureResult<RepeatedTrash, FlowyError>;
}

mod server_api;
mod server_api_mock;

pub use server_api::*;
// TODO: ignore mock files in production
pub use server_api_mock::*;

use crate::{
    entities::{
        app::{App, AppId, CreateAppParams, UpdateAppParams},
        trash::{RepeatedTrash, RepeatedTrashId},
        view::{CreateViewParams, RepeatedViewId, UpdateViewParams, View, ViewId},
        workspace::{CreateWorkspaceParams, RepeatedWorkspace, UpdateWorkspaceParams, Workspace, WorkspaceId},
    },
    errors::FlowyError,
};
use backend_service::configuration::ClientServerConfiguration;
use lib_infra::future::FutureResult;
use std::sync::Arc;

pub(crate) type Server = Arc<dyn WorkspaceServerAPI + Send + Sync>;

pub trait WorkspaceServerAPI {
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

pub(crate) fn construct_workspace_server(
    config: &ClientServerConfiguration,
) -> Arc<dyn WorkspaceServerAPI + Send + Sync> {
    if cfg!(feature = "http_server") {
        Arc::new(WorkspaceHttpServer::new(config.clone()))
    } else {
        Arc::new(WorkspaceServerMock {})
    }
}

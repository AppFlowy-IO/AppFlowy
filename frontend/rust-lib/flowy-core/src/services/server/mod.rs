mod server_api;
mod server_api_mock;

pub use server_api::*;
// TODO: ignore mock files in production
pub use server_api_mock::*;

use crate::{
    entities::{
        app::{App, AppIdentifier, CreateAppParams, UpdateAppParams},
        trash::{RepeatedTrash, TrashIdentifiers},
        view::{CreateViewParams, UpdateViewParams, View, ViewIdentifier, ViewIdentifiers},
        workspace::{CreateWorkspaceParams, RepeatedWorkspace, UpdateWorkspaceParams, Workspace, WorkspaceIdentifier},
    },
    errors::WorkspaceError,
};
use backend_service::configuration::ClientServerConfiguration;
use lib_infra::future::FutureResult;
use std::sync::Arc;

pub(crate) type Server = Arc<dyn WorkspaceServerAPI + Send + Sync>;

pub trait WorkspaceServerAPI {
    fn init(&self);

    // Workspace
    fn create_workspace(&self, token: &str, params: CreateWorkspaceParams) -> FutureResult<Workspace, WorkspaceError>;

    fn read_workspace(
        &self,
        token: &str,
        params: WorkspaceIdentifier,
    ) -> FutureResult<RepeatedWorkspace, WorkspaceError>;

    fn update_workspace(&self, token: &str, params: UpdateWorkspaceParams) -> FutureResult<(), WorkspaceError>;

    fn delete_workspace(&self, token: &str, params: WorkspaceIdentifier) -> FutureResult<(), WorkspaceError>;

    // View
    fn create_view(&self, token: &str, params: CreateViewParams) -> FutureResult<View, WorkspaceError>;

    fn read_view(&self, token: &str, params: ViewIdentifier) -> FutureResult<Option<View>, WorkspaceError>;

    fn delete_view(&self, token: &str, params: ViewIdentifiers) -> FutureResult<(), WorkspaceError>;

    fn update_view(&self, token: &str, params: UpdateViewParams) -> FutureResult<(), WorkspaceError>;

    // App
    fn create_app(&self, token: &str, params: CreateAppParams) -> FutureResult<App, WorkspaceError>;

    fn read_app(&self, token: &str, params: AppIdentifier) -> FutureResult<Option<App>, WorkspaceError>;

    fn update_app(&self, token: &str, params: UpdateAppParams) -> FutureResult<(), WorkspaceError>;

    fn delete_app(&self, token: &str, params: AppIdentifier) -> FutureResult<(), WorkspaceError>;

    // Trash
    fn create_trash(&self, token: &str, params: TrashIdentifiers) -> FutureResult<(), WorkspaceError>;

    fn delete_trash(&self, token: &str, params: TrashIdentifiers) -> FutureResult<(), WorkspaceError>;

    fn read_trash(&self, token: &str) -> FutureResult<RepeatedTrash, WorkspaceError>;
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

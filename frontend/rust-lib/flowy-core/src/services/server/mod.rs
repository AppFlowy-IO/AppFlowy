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
use lib_infra::future::ResultFuture;
use std::sync::Arc;

pub(crate) type Server = Arc<dyn WorkspaceServerAPI + Send + Sync>;

pub trait WorkspaceServerAPI {
    fn init(&self);

    // Workspace
    fn create_workspace(&self, token: &str, params: CreateWorkspaceParams) -> ResultFuture<Workspace, WorkspaceError>;

    fn read_workspace(
        &self,
        token: &str,
        params: WorkspaceIdentifier,
    ) -> ResultFuture<RepeatedWorkspace, WorkspaceError>;

    fn update_workspace(&self, token: &str, params: UpdateWorkspaceParams) -> ResultFuture<(), WorkspaceError>;

    fn delete_workspace(&self, token: &str, params: WorkspaceIdentifier) -> ResultFuture<(), WorkspaceError>;

    // View
    fn create_view(&self, token: &str, params: CreateViewParams) -> ResultFuture<View, WorkspaceError>;

    fn read_view(&self, token: &str, params: ViewIdentifier) -> ResultFuture<Option<View>, WorkspaceError>;

    fn delete_view(&self, token: &str, params: ViewIdentifiers) -> ResultFuture<(), WorkspaceError>;

    fn update_view(&self, token: &str, params: UpdateViewParams) -> ResultFuture<(), WorkspaceError>;

    // App
    fn create_app(&self, token: &str, params: CreateAppParams) -> ResultFuture<App, WorkspaceError>;

    fn read_app(&self, token: &str, params: AppIdentifier) -> ResultFuture<Option<App>, WorkspaceError>;

    fn update_app(&self, token: &str, params: UpdateAppParams) -> ResultFuture<(), WorkspaceError>;

    fn delete_app(&self, token: &str, params: AppIdentifier) -> ResultFuture<(), WorkspaceError>;

    // Trash
    fn create_trash(&self, token: &str, params: TrashIdentifiers) -> ResultFuture<(), WorkspaceError>;

    fn delete_trash(&self, token: &str, params: TrashIdentifiers) -> ResultFuture<(), WorkspaceError>;

    fn read_trash(&self, token: &str) -> ResultFuture<RepeatedTrash, WorkspaceError>;
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
